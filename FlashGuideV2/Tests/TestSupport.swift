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
        backgroundAmbientEV: Double? = nil,
        ambientContrastEV: Double? = nil,
        subjectHighlightRatio: Double = 0.04,
        subjectShadowRatio: Double = 0.12,
        depthEstimate: Double? = nil,
        manualDistanceOverride: Double? = nil,
        isDepthAvailable: Bool = true
    ) -> SceneInput {
        let resolvedBackgroundEV = backgroundAmbientEV ?? ambientMeterValue.map { $0 - 0.8 }
        let resolvedContrastEV = ambientContrastEV ?? {
            guard let ambientMeterValue, let resolvedBackgroundEV else { return nil }
            return abs(ambientMeterValue - resolvedBackgroundEV)
        }()

        return SceneInput(
            selectedCameraBody: cameraBody,
            selectedLens: lens,
            selectedFlashUnit: flashUnit,
            subjectDistanceMeters: subjectDistanceMeters,
            ambientPreference: ambientPreference,
            selectedTapPoint: nil,
            ambientEstimate: {
                guard let ambientMeterValue, let resolvedBackgroundEV, let resolvedContrastEV else {
                    return nil
                }

                return AmbientSceneEstimate(
                    subjectEV100: ambientMeterValue,
                    backgroundEV100: resolvedBackgroundEV,
                    ambientContrastEV: resolvedContrastEV,
                    subjectBackgroundDeltaEV: ambientMeterValue - resolvedBackgroundEV,
                    subjectHighlightRatio: subjectHighlightRatio,
                    subjectShadowRatio: subjectShadowRatio
                )
            }(),
            depthEstimate: depthEstimate,
            manualDistanceOverride: manualDistanceOverride,
            isDepthAvailable: isDepthAvailable,
            isSubjectSelectionLocked: false
        )
    }
}
