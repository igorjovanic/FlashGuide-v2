//
//  LiveAssistViewModel.swift
//  FlashGuideV2
//

import AVFoundation
import Combine
import CoreGraphics
import Foundation

@MainActor
final class LiveAssistViewModel: ObservableObject {
    @Published var availableCameraBodies: [CameraBody]
    @Published var availableLenses: [Lens]
    @Published var availableFlashUnits: [FlashUnit]
    @Published var selectedCameraBodyID: UUID
    @Published var selectedLensID: UUID
    @Published var selectedFlashUnitID: UUID
    @Published var ambientPreference: AmbientPreference
    @Published private(set) var authorizationState: CameraAuthorizationState
    @Published private(set) var depthSupportState: DepthSupportState
    @Published private(set) var depthEstimationState: CameraDepthEstimationState
    @Published private(set) var latestDepthEstimate: CameraDepthEstimate?
    @Published private(set) var latestAmbientEstimate: Double?
    @Published private(set) var isSessionRunning: Bool
    @Published private(set) var framePipelineState: CameraFramePipelineState
    @Published private(set) var subjectSelectionSupport: CameraSubjectSelectionSupport
    @Published var tapSelection: UserTapSelection?
    @Published var previewMarkerPoint: CGPoint?
    @Published var manualDistanceText = ""
    @Published var distanceInputError: String?
    @Published var recommendation: ExposureRecommendation?
    @Published var sceneInput = SceneInput.empty

    var session: AVCaptureSession {
        cameraService.session
    }

    private let cameraService: CameraServicing
    private let recommendationService: RecommendationServicing
    private let settingsService: SettingsServicing
    private var cancellables = Set<AnyCancellable>()

    init(
        cameraService: CameraServicing,
        recommendationService: RecommendationServicing,
        settingsService: SettingsServicing,
        availableCameraBodies: [CameraBody] = CameraBody.mockData,
        availableLenses: [Lens] = Lens.mockData,
        availableFlashUnits: [FlashUnit] = FlashUnit.mockData
    ) {
        self.cameraService = cameraService
        self.recommendationService = recommendationService
        self.settingsService = settingsService
        self.availableCameraBodies = availableCameraBodies
        self.availableLenses = availableLenses
        self.availableFlashUnits = availableFlashUnits
        let defaultCameraBody = availableCameraBodies.first(where: { $0.id == settingsService.defaultCameraBodyID }) ?? availableCameraBodies.first ?? .preview
        let defaultLens = availableLenses.first(where: { $0.id == settingsService.defaultLensID }) ?? availableLenses.first ?? .preview
        let defaultFlashUnit = availableFlashUnits.first(where: { $0.id == settingsService.defaultFlashUnitID }) ?? availableFlashUnits.first ?? .preview
        self.selectedCameraBodyID = defaultCameraBody.id
        self.selectedLensID = defaultLens.id
        self.selectedFlashUnitID = defaultFlashUnit.id
        self.ambientPreference = .balanced
        self.authorizationState = cameraService.authorizationState
        self.depthSupportState = cameraService.depthSupportState
        self.depthEstimationState = cameraService.depthEstimationState
        self.latestDepthEstimate = cameraService.latestDepthEstimate
        self.latestAmbientEstimate = cameraService.latestAmbientEstimate
        self.isSessionRunning = cameraService.isSessionRunning
        self.framePipelineState = cameraService.framePipelineState
        self.subjectSelectionSupport = cameraService.subjectSelectionSupport
        sceneInput.isDepthAvailable = cameraService.depthSupportState == .supported
        sceneInput.depthEstimate = cameraService.latestDepthEstimate?.value.acceptedMetersValue
        sceneInput.subjectDistanceMeters = sceneInput.depthEstimate ?? sceneInput.subjectDistanceMeters
        self.manualDistanceText = sceneInput.subjectDistanceMeters.formatted(.number.precision(.fractionLength(1)))
        sceneInput.selectedCameraBody = defaultCameraBody
        sceneInput.selectedLens = defaultLens
        sceneInput.selectedFlashUnit = defaultFlashUnit
        sceneInput.ambientPreference = ambientPreference
        self.cameraService.onStateChange = { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot: snapshot)
            }
        }
        bindRecommendationInputs()
        refreshRecommendation()
    }

    func onAppear() {
        Task {
            await requestCameraAccessIfNeeded()
            startSessionIfAuthorized()
        }
    }

    func onDisappear() {
        cameraService.stopSession()
        syncStateFromCamera()
    }

    func requestCameraAccessIfNeeded() async {
        authorizationState = await cameraService.requestAccessIfNeeded()
        syncStateFromCamera()
    }

    func refreshDepthSupport() {
        syncStateFromCamera()
    }

    func startSessionIfAuthorized() {
        guard authorizationState.isAuthorized else { return }
        cameraService.startSession()
        syncStateFromCamera()
    }

    func selectPoint(previewPoint: CGPoint, cameraPoint: CGPoint) {
        guard !sceneInput.isSubjectSelectionLocked else { return }

        let selection = UserTapSelection(
            normalizedX: max(0, min(1, Double(cameraPoint.x))),
            normalizedY: max(0, min(1, Double(cameraPoint.y)))
        )
        tapSelection = selection
        previewMarkerPoint = CGPoint(
            x: max(0, min(1, previewPoint.x)),
            y: max(0, min(1, previewPoint.y))
        )
        sceneInput.selectedTapPoint = selection
        sceneInput.depthEstimate = nil
        distanceInputError = nil
        cameraService.selectSubject(at: selection.point)
        refreshRecommendation()
    }

    func toggleSubjectSelectionLock() {
        guard tapSelection != nil else { return }
        sceneInput.isSubjectSelectionLocked.toggle()
        refreshRecommendation()
    }

    func clearSelectionLock() {
        sceneInput.isSubjectSelectionLocked = false
        refreshRecommendation()
    }

    func acceptEstimatedDistance() {
        guard let meters = latestDepthEstimate?.value.acceptedMetersValue else { return }
        sceneInput.depthEstimate = meters
        sceneInput.manualDistanceOverride = nil
        sceneInput.subjectDistanceMeters = meters
        manualDistanceText = meters.formatted(.number.precision(.fractionLength(2)))
        distanceInputError = nil
        refreshRecommendation()
    }

    func applyManualDistanceOverride() {
        let trimmedValue = manualDistanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            sceneInput.manualDistanceOverride = nil
            distanceInputError = nil
            return
        }

        guard let value = Double(trimmedValue.replacingOccurrences(of: ",", with: ".")), value > 0 else {
            distanceInputError = "Enter a valid distance in meters."
            return
        }

        sceneInput.manualDistanceOverride = value
        sceneInput.subjectDistanceMeters = value
        distanceInputError = nil
        refreshRecommendation()
    }

    var canAcceptEstimatedDistance: Bool {
        latestDepthEstimate?.value.acceptedMetersValue != nil
    }

    var selectedCameraBody: CameraBody? {
        availableCameraBodies.first(where: { $0.id == selectedCameraBodyID })
    }

    var selectedLens: Lens? {
        availableLenses.first(where: { $0.id == selectedLensID })
    }

    var selectedFlashUnit: FlashUnit? {
        availableFlashUnits.first(where: { $0.id == selectedFlashUnitID })
    }

    var distanceSourceLabel: String {
        if sceneInput.manualDistanceOverride != nil {
            "Manual override"
        } else if sceneInput.depthEstimate != nil {
            "Estimated distance"
        } else {
            "Base subject distance"
        }
    }

    var isConfidenceLow: Bool {
        (recommendation?.confidenceScore ?? 1.0) < 0.65
    }

    func updateAvailableGear(
        cameraBodies: [CameraBody],
        lenses: [Lens],
        flashUnits: [FlashUnit]
    ) {
        availableCameraBodies = cameraBodies
        availableLenses = lenses
        availableFlashUnits = flashUnits

        if let defaultCameraBody = cameraBodies.first(where: { $0.id == settingsService.defaultCameraBodyID }) {
            selectedCameraBodyID = defaultCameraBody.id
        } else if cameraBodies.contains(where: { $0.id == selectedCameraBodyID }) == false,
                  let firstCameraBody = cameraBodies.first {
            selectedCameraBodyID = firstCameraBody.id
        }

        if let defaultLens = lenses.first(where: { $0.id == settingsService.defaultLensID }) {
            selectedLensID = defaultLens.id
        } else if lenses.contains(where: { $0.id == selectedLensID }) == false,
                  let firstLens = lenses.first {
            selectedLensID = firstLens.id
        }

        if let defaultFlashUnit = flashUnits.first(where: { $0.id == settingsService.defaultFlashUnitID }) {
            selectedFlashUnitID = defaultFlashUnit.id
        } else if flashUnits.contains(where: { $0.id == selectedFlashUnitID }) == false,
                  let firstFlashUnit = flashUnits.first {
            selectedFlashUnitID = firstFlashUnit.id
        }

        refreshRecommendation()
    }

    private func syncStateFromCamera() {
        authorizationState = cameraService.authorizationState
        depthSupportState = cameraService.depthSupportState
        depthEstimationState = cameraService.depthEstimationState
        latestDepthEstimate = cameraService.latestDepthEstimate
        latestAmbientEstimate = cameraService.latestAmbientEstimate
        isSessionRunning = cameraService.isSessionRunning
        framePipelineState = cameraService.framePipelineState
        subjectSelectionSupport = cameraService.subjectSelectionSupport
        sceneInput.isDepthAvailable = depthSupportState == .supported
    }

    private func apply(snapshot: CameraStateSnapshot) {
        authorizationState = snapshot.authorizationState
        depthSupportState = snapshot.depthSupportState
        depthEstimationState = snapshot.depthEstimationState
        latestDepthEstimate = snapshot.latestDepthEstimate
        latestAmbientEstimate = snapshot.latestAmbientEstimate
        isSessionRunning = snapshot.isSessionRunning
        framePipelineState = snapshot.framePipelineState
        subjectSelectionSupport = snapshot.subjectSelectionSupport
        sceneInput.isDepthAvailable = snapshot.depthSupportState == .supported
        if let estimateMeters = snapshot.latestDepthEstimate?.value.acceptedMetersValue {
            sceneInput.depthEstimate = estimateMeters
            if sceneInput.manualDistanceOverride == nil {
                sceneInput.subjectDistanceMeters = estimateMeters
            }
        } else {
            sceneInput.depthEstimate = nil
        }
        sceneInput.ambientMeterValue = snapshot.latestAmbientEstimate
        refreshRecommendation()
    }

    private func bindRecommendationInputs() {
        $selectedCameraBodyID
            .sink { [weak self] _ in self?.refreshRecommendation() }
            .store(in: &cancellables)
        $selectedLensID
            .sink { [weak self] _ in self?.refreshRecommendation() }
            .store(in: &cancellables)
        $selectedFlashUnitID
            .sink { [weak self] _ in self?.refreshRecommendation() }
            .store(in: &cancellables)
        $ambientPreference
            .sink { [weak self] preference in
                self?.sceneInput.ambientPreference = preference
                self?.refreshRecommendation()
            }
            .store(in: &cancellables)
    }

    private func refreshRecommendation() {
        guard let cameraBody = selectedCameraBody,
              let lens = selectedLens,
              let flashUnit = selectedFlashUnit else {
            recommendation = nil
            return
        }

        sceneInput.selectedCameraBody = cameraBody
        sceneInput.selectedLens = lens
        sceneInput.selectedFlashUnit = flashUnit
        sceneInput.ambientPreference = ambientPreference
        sceneInput.selectedTapPoint = tapSelection
        sceneInput.isDepthAvailable = depthSupportState == .supported

        recommendation = recommendationService.makeRecommendation(for: sceneInput)
    }
}
