//
//  RecommendationService.swift
//  FlashGuideV2
//

import Foundation

protocol RecommendationServicing {
    func makeRecommendation(for sceneInput: SceneInput) -> ExposureRecommendation
}

struct RecommendationService: RecommendationServicing {
    private let engine: ExposureRecommendationEngine

    init(engine: ExposureRecommendationEngine = DefaultExposureRecommendationEngine()) {
        self.engine = engine
    }

    func makeRecommendation(for sceneInput: SceneInput) -> ExposureRecommendation {
        engine.makeRecommendation(
            cameraBody: sceneInput.selectedCameraBody,
            lens: sceneInput.selectedLens,
            flashUnit: sceneInput.selectedFlashUnit,
            sceneInput: sceneInput
        )
    }
}
