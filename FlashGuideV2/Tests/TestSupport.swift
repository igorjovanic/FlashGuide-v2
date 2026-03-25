//
//  TestSupport.swift
//  FlashGuideV2
//

import Foundation

enum TestSupport {
    static let sampleSceneInput = SceneInput.preview

    static func makeSceneInput(
        cameraBody: CameraBody = CameraBody.preview,
        lens: Lens = Lens.preview,
        flashUnit: FlashUnit = FlashUnit.preview,
        subjectDistanceMeters: Double = 2.0,
        ambientPreference: AmbientPreference = .balanced,
        ambientMeterValue: Double? = 8.0,
        depthEstimate: Double? = nil,
        manualDistanceOverride: Double? = nil,
        isDepthAvailable: Bool = true
    ) -> SceneInput {
        SceneInput(
            selectedCameraBody: cameraBody,
            selectedLens: lens,
            selectedFlashUnit: flashUnit,
            subjectDistanceMeters: subjectDistanceMeters,
            ambientPreference: ambientPreference,
            selectedTapPoint: nil,
            ambientMeterValue: ambientMeterValue,
            depthEstimate: depthEstimate,
            manualDistanceOverride: manualDistanceOverride,
            isDepthAvailable: isDepthAvailable,
            isSubjectSelectionLocked: false
        )
    }
}
