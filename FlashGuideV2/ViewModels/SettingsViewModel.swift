//
//  SettingsViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var depthAssistanceEnabled: Bool

    private let settingsService: SettingsServicing

    init(settingsService: SettingsServicing) {
        self.settingsService = settingsService
        self.depthAssistanceEnabled = settingsService.isDepthAssistanceEnabled
    }

    func persist() {
        settingsService.isDepthAssistanceEnabled = depthAssistanceEnabled
    }
}
