//
//  SettingsService.swift
//  FlashGuideV2
//

import Foundation

protocol SettingsServicing: AnyObject {
    var isDepthAssistanceEnabled: Bool { get set }
}

final class SettingsService: SettingsServicing {
    private let defaults = UserDefaults.standard
    private let depthAssistanceKey = "flashassist.settings.depthAssistanceEnabled"

    var isDepthAssistanceEnabled: Bool {
        get { defaults.object(forKey: depthAssistanceKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: depthAssistanceKey) }
    }
}
