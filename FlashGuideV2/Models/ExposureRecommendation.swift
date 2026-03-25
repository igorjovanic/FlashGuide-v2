//
//  ExposureRecommendation.swift
//  FlashGuideV2
//

import Foundation

struct ExposureRecommendation: Equatable, Hashable, Identifiable, Codable {
    let id: UUID
    var shutterSpeed: String
    var aperture: String
    var iso: String
    var flashPowerStep: String
    var confidenceScore: Double
    var reasoning: [String]
    var warnings: [String]

    init(
        id: UUID = UUID(),
        shutterSpeed: String,
        aperture: String,
        iso: String,
        flashPowerStep: String,
        confidenceScore: Double,
        reasoning: [String],
        warnings: [String]
    ) {
        self.id = id
        self.shutterSpeed = shutterSpeed
        self.aperture = aperture
        self.iso = iso
        self.flashPowerStep = flashPowerStep
        self.confidenceScore = confidenceScore
        self.reasoning = reasoning
        self.warnings = warnings
    }

    static let preview = ExposureRecommendation(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777") ?? UUID(),
        shutterSpeed: "1/200",
        aperture: "f/4",
        iso: "ISO 200",
        flashPowerStep: "1/8",
        confidenceScore: 0.86,
        reasoning: [
            "Balanced ambient preference keeps sync speed near the camera limit.",
            "Subject distance suggests a moderate aperture for depth and flash efficiency."
        ],
        warnings: []
    )

    static let mockData: [ExposureRecommendation] = [
        .preview,
        ExposureRecommendation(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888") ?? UUID(),
            shutterSpeed: "1/250",
            aperture: "f/2.8",
            iso: "ISO 400",
            flashPowerStep: "1/16",
            confidenceScore: 0.72,
            reasoning: [
                "Freeze motion preference prioritizes the fastest supported shutter speed.",
                "Higher ISO preserves ambient detail while reducing flash load."
            ],
            warnings: [
                "Selected shutter speed may exceed some bodies' native flash sync speed."
            ]
        )
    ]
}
