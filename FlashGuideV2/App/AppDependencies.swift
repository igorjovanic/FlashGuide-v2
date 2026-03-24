//
//  AppDependencies.swift
//  FlashGuideV2
//

import Foundation

struct AppDependencies {
    let recommendationService: RecommendationServicing
    let cameraService: CameraServicing
    let gearProfileRepository: GearProfileRepository

    static let live = AppDependencies(
        recommendationService: RecommendationService(),
        cameraService: CameraService(),
        gearProfileRepository: GearProfileRepository()
    )
}
