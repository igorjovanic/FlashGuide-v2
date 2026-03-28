//
//  FlashAssistApp.swift
//  FlashGuideV2
//

import SwiftData
import SwiftUI

@main
struct FlashAssistApp: App {
    private let dependencies: AppDependencies
    private let modelContainer: ModelContainer

    init() {
        let dependencies = AppDependencies.live
        let modelContainer = FlashAssistModelContainer.makeSharedContainer()

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
