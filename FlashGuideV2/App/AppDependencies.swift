//
//  AppDependencies.swift
//  FlashGuideV2
//

import Foundation

struct AppDependencies {
    let recommendationService: RecommendationServicing
    let cameraService: CameraServicing
    let gearProfileRepository: GearProfileRepository
    let settingsService: SettingsServicing

    static let live = AppDependencies(
        recommendationService: RecommendationService(),
        cameraService: CameraSessionManager(),
        gearProfileRepository: GearProfileRepository(),
        settingsService: SettingsService()
    )
}
