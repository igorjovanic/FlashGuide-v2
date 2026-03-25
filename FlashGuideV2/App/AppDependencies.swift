//
//  AppDependencies.swift
//  FlashGuideV2
//

import Foundation

struct AppDependencies {
    let recommendationService: RecommendationServicing
    let historyService: RecommendationHistoryServicing
    let cameraService: CameraServicing
    let gearProfileRepository: GearProfileRepository
    let settingsService: SettingsServicing

    static let live = AppDependencies(
        recommendationService: RecommendationService(),
        historyService: RecommendationHistoryService(),
        cameraService: CameraSessionManager(),
        gearProfileRepository: GearProfileRepository(),
        settingsService: SettingsService()
    )
}
