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
    @Published private(set) var authorizationState: CameraAuthorizationState
    @Published private(set) var depthSupportState: DepthSupportState
    @Published private(set) var depthEstimationState: CameraDepthEstimationState
    @Published private(set) var latestDepthEstimate: CameraDepthEstimate?
    @Published private(set) var isSessionRunning: Bool
    @Published private(set) var framePipelineState: CameraFramePipelineState
    @Published private(set) var subjectSelectionSupport: CameraSubjectSelectionSupport
    @Published var tapSelection: UserTapSelection?
    @Published var previewMarkerPoint: CGPoint?
    @Published var manualDistanceText = ""
    @Published var distanceInputError: String?
    @Published var sceneInput = SceneInput.empty

    var session: AVCaptureSession {
        cameraService.session
    }

    private let cameraService: CameraServicing

    init(cameraService: CameraServicing) {
        self.cameraService = cameraService
        self.authorizationState = cameraService.authorizationState
        self.depthSupportState = cameraService.depthSupportState
        self.depthEstimationState = cameraService.depthEstimationState
        self.latestDepthEstimate = cameraService.latestDepthEstimate
        self.isSessionRunning = cameraService.isSessionRunning
        self.framePipelineState = cameraService.framePipelineState
        self.subjectSelectionSupport = cameraService.subjectSelectionSupport
        sceneInput.isDepthAvailable = cameraService.depthSupportState == .supported
        sceneInput.depthEstimate = cameraService.latestDepthEstimate?.value.acceptedMetersValue
        sceneInput.subjectDistanceMeters = sceneInput.depthEstimate ?? sceneInput.subjectDistanceMeters
        self.manualDistanceText = sceneInput.subjectDistanceMeters.formatted(.number.precision(.fractionLength(1)))
        self.cameraService.onStateChange = { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot: snapshot)
            }
        }
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
    }

    func toggleSubjectSelectionLock() {
        guard tapSelection != nil else { return }
        sceneInput.isSubjectSelectionLocked.toggle()
    }

    func clearSelectionLock() {
        sceneInput.isSubjectSelectionLocked = false
    }

    func acceptEstimatedDistance() {
        guard let meters = latestDepthEstimate?.value.acceptedMetersValue else { return }
        sceneInput.depthEstimate = meters
        sceneInput.manualDistanceOverride = nil
        sceneInput.subjectDistanceMeters = meters
        manualDistanceText = meters.formatted(.number.precision(.fractionLength(2)))
        distanceInputError = nil
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
    }

    var canAcceptEstimatedDistance: Bool {
        latestDepthEstimate?.value.acceptedMetersValue != nil
    }

    private func syncStateFromCamera() {
        authorizationState = cameraService.authorizationState
        depthSupportState = cameraService.depthSupportState
        depthEstimationState = cameraService.depthEstimationState
        latestDepthEstimate = cameraService.latestDepthEstimate
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
        isSessionRunning = snapshot.isSessionRunning
        framePipelineState = snapshot.framePipelineState
        subjectSelectionSupport = snapshot.subjectSelectionSupport
        sceneInput.isDepthAvailable = snapshot.depthSupportState == .supported
    }
}
