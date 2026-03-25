//
//  HistoryViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine

final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [RecommendationHistoryEntry] = []

    private let historyService: RecommendationHistoryServicing

    init(historyService: RecommendationHistoryServicing) {
        self.historyService = historyService
        reload()
    }

    func reload() {
        entries = historyService.loadHistory()
    }

    func clear() {
        historyService.clear()
        reload()
    }
}
