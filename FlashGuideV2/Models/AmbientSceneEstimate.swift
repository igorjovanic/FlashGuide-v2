//
//  AmbientSceneEstimate.swift
//  FlashGuideV2
//

import Foundation

enum AmbientSceneKind: String, Equatable, Hashable, Codable {
    case daylight
    case goldenHour
    case indoorLowLight
    case night

    var displayName: String {
        switch self {
        case .daylight:
            "daylight"
        case .goldenHour:
            "golden hour"
        case .indoorLowLight:
            "indoor low light"
        case .night:
            "night"
        }
    }
}

struct AmbientSceneEstimate: Equatable, Hashable, Codable {
    let subjectEV100: Double
    let backgroundEV100: Double
    let ambientContrastEV: Double
    let subjectBackgroundDeltaEV: Double
    let subjectHighlightRatio: Double
    let subjectShadowRatio: Double

    var sceneKind: AmbientSceneKind {
        let sceneEV = max(subjectEV100, backgroundEV100)

        if sceneEV >= 11.5 {
            return .daylight
        }

        if sceneEV >= 8.0 {
            return subjectHighlightRatio >= 0.12 ? .goldenHour : .indoorLowLight
        }

        if sceneEV >= 5.2 {
            return .indoorLowLight
        }

        return .night
    }
}
