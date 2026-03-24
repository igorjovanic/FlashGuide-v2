//
//  GearProfilesViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine
import SwiftData

final class GearProfilesViewModel: ObservableObject {
    private let repository: GearProfileRepository

    init(repository: GearProfileRepository) {
        self.repository = repository
    }

    func seedIfNeeded(using modelContext: ModelContext) {
        repository.seedSampleDataIfNeeded(using: modelContext)
    }
}
