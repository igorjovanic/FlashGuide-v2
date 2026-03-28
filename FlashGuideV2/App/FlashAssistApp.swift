//
//  FlashAssistApp.swift
//  FlashGuideV2
//

import SwiftData
import SwiftUI

@main
struct FlashAssistApp: App {
    private enum LegacyCleanup {
        static let didPurgeSavedGearAndHistoryKey = "flashassist.migrations.didPurgeSavedGearAndHistory"
        static let historyEntriesKey = "flashassist.history.entries"
    }

    private let dependencies: AppDependencies
    private let modelContainer: ModelContainer

    init() {
        let dependencies = AppDependencies.live
        let modelContainer = FlashAssistModelContainer.makeSharedContainer()

        let defaults = UserDefaults.standard
        if defaults.bool(forKey: LegacyCleanup.didPurgeSavedGearAndHistoryKey) == false {
            try? dependencies.gearProfileRepository.clearAll(
                using: modelContainer.mainContext,
                settingsService: dependencies.settingsService
            )
            defaults.removeObject(forKey: LegacyCleanup.historyEntriesKey)
            defaults.set(true, forKey: LegacyCleanup.didPurgeSavedGearAndHistoryKey)
        }

        self.dependencies = dependencies
        self.modelContainer = modelContainer
    }

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
                .environment(\.appDependencies, dependencies)
        }
        .modelContainer(modelContainer)
    }
}
