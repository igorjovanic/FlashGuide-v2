//
//  ManualCalculatorViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine

final class ManualCalculatorViewModel: ObservableObject {
    @Published var sceneInput = SceneInput.empty
    @Published var recommendation: ExposureRecommendation?

    private let recommendationService: RecommendationServicing

    init(recommendationService: RecommendationServicing) {
        self.recommendationService = recommendationService
    }

    func generateRecommendation() {
        recommendation = recommendationService.makeRecommendation(for: sceneInput)
    }
}
