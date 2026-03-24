//
//  UserTapSelection.swift
//  FlashGuideV2
//

import CoreGraphics
import Foundation

struct UserTapSelection: Equatable, Codable {
    var normalizedX: Double
    var normalizedY: Double
    var timestamp: Date

    var point: CGPoint {
        CGPoint(x: normalizedX, y: normalizedY)
    }

    init(normalizedX: Double, normalizedY: Double, timestamp: Date = .now) {
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.timestamp = timestamp
    }
}
