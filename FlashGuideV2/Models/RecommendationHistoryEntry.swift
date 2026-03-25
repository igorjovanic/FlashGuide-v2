//
//  RecommendationHistoryEntry.swift
//  FlashGuideV2
//

import Foundation

struct RecommendationHistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let source: String
    let cameraName: String
    let lensName: String
    let flashName: String
    let distanceSource: String
    let ambientPreference: String
    let recommendation: ExposureRecommendation

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        source: String,
        cameraName: String,
        lensName: String,
        flashName: String,
        distanceSource: String,
        ambientPreference: String,
        recommendation: ExposureRecommendation
    ) {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.cameraName = cameraName
        self.lensName = lensName
        self.flashName = flashName
        self.distanceSource = distanceSource
        self.ambientPreference = ambientPreference
        self.recommendation = recommendation
    }
}
