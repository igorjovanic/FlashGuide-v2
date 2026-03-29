//
//  AmbientSceneEstimate.swift
//  FlashGuideV2
//

import Foundation

struct AmbientSceneEstimate: Equatable, Hashable, Codable {
    let subjectEV100: Double
    let backgroundEV100: Double
    let ambientContrastEV: Double
    let subjectBackgroundDeltaEV: Double
    let subjectHighlightRatio: Double
    let subjectShadowRatio: Double
}
