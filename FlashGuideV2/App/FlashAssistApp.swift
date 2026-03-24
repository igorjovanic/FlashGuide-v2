//
//  FlashAssistApp.swift
//  FlashGuideV2
//

import SwiftData
import SwiftUI

@main
struct FlashAssistApp: App {
    private let dependencies = AppDependencies.live
    private let modelContainer = FlashAssistModelContainer.makeSharedContainer()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
                .environment(\.appDependencies, dependencies)
        }
        .modelContainer(modelContainer)
    }
}
