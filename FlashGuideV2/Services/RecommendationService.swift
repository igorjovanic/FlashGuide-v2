//
//  RecommendationService.swift
//  FlashGuideV2
//

import Foundation

protocol RecommendationServicing {
    func makeRecommendation(for sceneInput: SceneInput) -> ExposureRecommendation
}

struct RecommendationService: RecommendationServicing {
    func makeRecommendation(for sceneInput: SceneInput) -> ExposureRecommendation {
        let meteredAmbient = sceneInput.ambientMeterValue ?? 8.0
        let shutter: String

        switch sceneInput.ambientPreference {
        case .balanced:
            shutter = sceneInput.selectedCameraBody.flashSyncSpeed
        case .darkerBackground:
            shutter = "1/200"
        case .brighterAmbient:
            shutter = "1/125"
        case .freezeMotion:
            shutter = "1/250"
        }

        let aperture = sceneInput.subjectDistanceMeters > 3 ? "f/2.8" : "f/4"
        let iso = meteredAmbient < 6 ? "ISO 400" : "ISO 200"
        let flashPowerStep = sceneInput.selectedFlashUnit.supportedPowerSteps.dropFirst(3).first ?? sceneInput.selectedFlashUnit.supportedPowerSteps.last ?? "1/8"
        var warnings: [String] = []

        if sceneInput.manualDistanceOverride != nil {
            warnings.append("Manual distance override is active.")
        }

        if !sceneInput.isDepthAvailable {
            warnings.append("Depth data unavailable, recommendation relies on manual distance input.")
        }

        return ExposureRecommendation(
            shutterSpeed: shutter,
            aperture: aperture,
            iso: iso,
            flashPowerStep: flashPowerStep,
            confidenceScore: sceneInput.isDepthAvailable ? 0.84 : 0.68,
            reasoning: [
                "\(sceneInput.ambientPreference.rawValue) ambient preference shaped the shutter recommendation.",
                "Subject distance of \(sceneInput.subjectDistanceMeters.formatted(.number.precision(.fractionLength(1))))m informed aperture and flash output."
            ],
            warnings: warnings
        )
    }
}
