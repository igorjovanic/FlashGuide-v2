//
//  SettingsViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var depthAssistanceEnabled: Bool
    @Published var distanceUnit: DistanceUnit

    private let settingsService: SettingsServicing

    init(settingsService: SettingsServicing) {
        self.settingsService = settingsService
        self.depthAssistanceEnabled = settingsService.isDepthAssistanceEnabled
        self.distanceUnit = settingsService.distanceUnit
    }

    func persist() {
        settingsService.isDepthAssistanceEnabled = depthAssistanceEnabled
        settingsService.distanceUnit = distanceUnit
    }
}
