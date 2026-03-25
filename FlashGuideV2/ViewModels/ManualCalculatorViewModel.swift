//
//  ManualCalculatorViewModel.swift
//  FlashGuideV2
//

import Combine
import Foundation

final class ManualCalculatorViewModel: ObservableObject {
    @Published var availableCameraBodies: [CameraBody]
    @Published var availableLenses: [Lens]
    @Published var availableFlashUnits: [FlashUnit]
    @Published var selectedCameraBodyID: UUID
    @Published var selectedLensID: UUID
    @Published var selectedFlashUnitID: UUID
    @Published var subjectDistanceText: String
    @Published var ambientPreference: AmbientPreference
    @Published var validationErrors: [String] = []
    @Published var recommendation: ExposureRecommendation?
    @Published private(set) var sceneInput: SceneInput
    private let recommendationService: RecommendationServicing

    init(
        recommendationService: RecommendationServicing = RecommendationService(),
        availableCameraBodies: [CameraBody] = CameraBody.mockData,
        availableLenses: [Lens] = Lens.mockData,
        availableFlashUnits: [FlashUnit] = FlashUnit.mockData
    ) {
        self.recommendationService = recommendationService
        self.availableCameraBodies = availableCameraBodies
        self.availableLenses = availableLenses
        self.availableFlashUnits = availableFlashUnits

        let defaultCameraBody = availableCameraBodies.first ?? .preview
        let defaultLens = availableLenses.first ?? .preview
        let defaultFlashUnit = availableFlashUnits.first ?? .preview

        self.selectedCameraBodyID = defaultCameraBody.id
        self.selectedLensID = defaultLens.id
        self.selectedFlashUnitID = defaultFlashUnit.id
        self.subjectDistanceText = "2.0"
        self.ambientPreference = .balanced
        self.sceneInput = SceneInput(
            selectedCameraBody: defaultCameraBody,
            selectedLens: defaultLens,
            selectedFlashUnit: defaultFlashUnit,
            subjectDistanceMeters: 2.0,
            ambientPreference: .balanced,
            selectedTapPoint: nil,
            ambientMeterValue: nil,
            depthEstimate: nil,
            manualDistanceOverride: nil,
            isDepthAvailable: false,
            isSubjectSelectionLocked: false
        )
    }

    func generateRecommendation() {
        validationErrors = validateInputs()

        guard validationErrors.isEmpty else {
            recommendation = nil
            return
        }

        guard
            let cameraBody = selectedCameraBody,
            let lens = selectedLens,
            let flashUnit = selectedFlashUnit,
            let subjectDistance = parsedSubjectDistance
        else {
            validationErrors = ["Unable to read the selected gear."]
            recommendation = nil
            return
        }

        sceneInput = SceneInput(
            selectedCameraBody: cameraBody,
            selectedLens: lens,
            selectedFlashUnit: flashUnit,
            subjectDistanceMeters: subjectDistance,
            ambientPreference: ambientPreference,
            selectedTapPoint: nil,
            ambientMeterValue: nil,
            depthEstimate: nil,
            manualDistanceOverride: nil,
            isDepthAvailable: false,
            isSubjectSelectionLocked: false
        )

        recommendation = recommendationService.makeRecommendation(for: sceneInput)
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

    var parsedSubjectDistance: Double? {
        parseDecimal(subjectDistanceText)
    }

    func sanitizeSubjectDistance(_ value: String) {
        let filtered = value.filter { character in
            character.isNumber || character == "." || character == ","
        }
        subjectDistanceText = filtered
    }

    private func validateInputs() -> [String] {
        var errors: [String] = []

        if selectedCameraBody == nil {
            errors.append("Select a camera body.")
        }

        if selectedLens == nil {
            errors.append("Select a lens.")
        }

        if selectedFlashUnit == nil {
            errors.append("Select a flash.")
        }

        guard !subjectDistanceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errors.append("Enter a subject distance in meters.")
            return errors
        }

        guard let subjectDistance = parsedSubjectDistance else {
            errors.append("Subject distance must be a valid number.")
            return errors
        }

        if subjectDistance <= 0 {
            errors.append("Subject distance must be greater than zero.")
        }

        return errors
    }

    private func parseDecimal(_ value: String) -> Double? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else {
            return nil
        }

        return Double(normalized)
    }
}
