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
        let shutter = sceneInput.ambientEV > 10 ? "1/200" : "1/125"
        let aperture = sceneInput.subjectDistanceMeters > 3 ? "f/2.8" : "f/4"
        let iso = sceneInput.ambientEV < 6 ? "ISO 400" : "ISO 200"

        return ExposureRecommendation(
            shutterSpeedDescription: shutter,
            apertureDescription: aperture,
            isoDescription: iso,
            flashPowerDescription: "1/8",
            summary: "Starter recommendation for a subject at \(sceneInput.subjectDistanceMeters.formatted(.number.precision(.fractionLength(1))))m."
        )
    }
}
