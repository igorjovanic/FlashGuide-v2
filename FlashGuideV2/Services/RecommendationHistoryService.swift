//
//  RecommendationHistoryService.swift
//  FlashGuideV2
//

import Foundation

protocol RecommendationHistoryServicing: AnyObject {
    func loadHistory() -> [RecommendationHistoryEntry]
    func record(_ entry: RecommendationHistoryEntry)
    func clear()
}

final class RecommendationHistoryService: RecommendationHistoryServicing {
    private let defaults = UserDefaults.standard
    private let historyKey = "flashassist.history.entries"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadHistory() -> [RecommendationHistoryEntry] {
        guard let data = defaults.data(forKey: historyKey),
              let entries = try? decoder.decode([RecommendationHistoryEntry].self, from: data) else {
            return []
        }

        return entries.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func record(_ entry: RecommendationHistoryEntry) {
        var entries = loadHistory()
        let duplicate = entries.first {
            $0.source == entry.source
                && $0.cameraName == entry.cameraName
                && $0.lensName == entry.lensName
                && $0.flashName == entry.flashName
                && $0.distanceSource == entry.distanceSource
                && $0.ambientPreference == entry.ambientPreference
                && $0.recommendation.shutterSpeed == entry.recommendation.shutterSpeed
                && $0.recommendation.aperture == entry.recommendation.aperture
                && $0.recommendation.iso == entry.recommendation.iso
                && $0.recommendation.flashPowerStep == entry.recommendation.flashPowerStep
        }

        guard duplicate == nil else { return }

        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(50))

        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: historyKey)
        }
    }

    func clear() {
        defaults.removeObject(forKey: historyKey)
    }
}
