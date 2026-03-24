//
//  SceneInput.swift
//  FlashGuideV2
//

import CoreGraphics
import Foundation

struct SceneInput: Equatable, Codable {
    var subjectDistanceMeters: Double
    var ambientEV: Double
    var selectedPoint: CGPoint?
    var notes: String

    static let empty = SceneInput(
        subjectDistanceMeters: 2.0,
        ambientEV: 8.0,
        selectedPoint: nil,
        notes: ""
    )
}
