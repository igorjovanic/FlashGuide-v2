//
//  ExposureRecommendation.swift
//  FlashGuideV2
//

import Foundation

struct ExposureRecommendation: Equatable, Identifiable, Codable {
    let id: UUID
    var shutterSpeedDescription: String
    var apertureDescription: String
    var isoDescription: String
    var flashPowerDescription: String
    var summary: String

    init(
        id: UUID = UUID(),
        shutterSpeedDescription: String,
        apertureDescription: String,
        isoDescription: String,
        flashPowerDescription: String,
        summary: String
    ) {
        self.id = id
        self.shutterSpeedDescription = shutterSpeedDescription
        self.apertureDescription = apertureDescription
        self.isoDescription = isoDescription
        self.flashPowerDescription = flashPowerDescription
        self.summary = summary
    }

    static let placeholder = ExposureRecommendation(
        shutterSpeedDescription: "1/200",
        apertureDescription: "f/4",
        isoDescription: "ISO 200",
        flashPowerDescription: "1/8",
        summary: "Placeholder recommendation based on your current inputs."
    )
}
