//
//  SettingsService.swift
//  FlashGuideV2
//

import Foundation

protocol SettingsServicing: AnyObject {
    var isDepthAssistanceEnabled: Bool { get set }
    var defaultCameraBodyID: UUID? { get set }
    var defaultLensID: UUID? { get set }
    var defaultFlashUnitID: UUID? { get set }
}

final class SettingsService: SettingsServicing {
    private let defaults = UserDefaults.standard
    private let depthAssistanceKey = "flashassist.settings.depthAssistanceEnabled"
    private let defaultCameraBodyKey = "flashassist.settings.defaultCameraBodyID"
    private let defaultLensKey = "flashassist.settings.defaultLensID"
    private let defaultFlashUnitKey = "flashassist.settings.defaultFlashUnitID"

    var isDepthAssistanceEnabled: Bool {
        get { defaults.object(forKey: depthAssistanceKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: depthAssistanceKey) }
    }

    var defaultCameraBodyID: UUID? {
        get { uuid(forKey: defaultCameraBodyKey) }
        set { set(uuid: newValue, forKey: defaultCameraBodyKey) }
    }

    var defaultLensID: UUID? {
        get { uuid(forKey: defaultLensKey) }
        set { set(uuid: newValue, forKey: defaultLensKey) }
    }

    var defaultFlashUnitID: UUID? {
        get { uuid(forKey: defaultFlashUnitKey) }
        set { set(uuid: newValue, forKey: defaultFlashUnitKey) }
    }

    private func uuid(forKey key: String) -> UUID? {
        guard let rawValue = defaults.string(forKey: key) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    private func set(uuid: UUID?, forKey key: String) {
        defaults.set(uuid?.uuidString, forKey: key)
    }
}
