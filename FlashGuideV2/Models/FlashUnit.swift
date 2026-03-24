//
//  FlashUnit.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

@Model
final class FlashUnit {
    var name: String
    var guideNumber: Double
    var powerLevels: [String]
    var createdAt: Date

    init(
        name: String = "Manual Flash",
        guideNumber: Double = 60.0,
        powerLevels: [String] = ["1/1", "1/2", "1/4", "1/8", "1/16"],
        createdAt: Date = .now
    ) {
        self.name = name
        self.guideNumber = guideNumber
        self.powerLevels = powerLevels
        self.createdAt = createdAt
    }
}
