//
//  UserTapSelection.swift
//  FlashGuideV2
//

import CoreGraphics
import Foundation

struct UserTapSelection: Equatable, Hashable, Codable {
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

    static let preview = UserTapSelection(normalizedX: 0.42, normalizedY: 0.36)

    static let mockData: [UserTapSelection] = [
        UserTapSelection(normalizedX: 0.42, normalizedY: 0.36),
        UserTapSelection(normalizedX: 0.68, normalizedY: 0.54)
    ]
}
