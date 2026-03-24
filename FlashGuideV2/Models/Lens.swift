//
//  Lens.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

@Model
final class Lens {
    var name: String
    var apertureMin: Double
    var apertureMax: Double
    var focalLengthDescription: String
    var createdAt: Date

    init(
        name: String = "Standard Lens",
        apertureMin: Double = 1.8,
        apertureMax: Double = 16.0,
        focalLengthDescription: String = "50mm",
        createdAt: Date = .now
    ) {
        self.name = name
        self.apertureMin = apertureMin
        self.apertureMax = apertureMax
        self.focalLengthDescription = focalLengthDescription
        self.createdAt = createdAt
    }
}
