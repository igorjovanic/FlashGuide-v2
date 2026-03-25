//
//  HomeView.swift
//  FlashGuideV2
//

import SwiftUI

struct HomeView: View {
    @Environment(\.appDependencies) private var dependencies
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List(viewModel.destinations) { destination in
                NavigationLink(value: destination) {
                    Label(destination.rawValue, systemImage: destination.systemImage)
                        .font(.body.weight(.medium))
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("FlashAssist")
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .manualCalculator:
                    ManualCalculatorView(
                        viewModel: ManualCalculatorViewModel(
                            recommendationService: dependencies.recommendationService,
                            settingsService: dependencies.settingsService
                        )
                    )
                case .liveAssist:
                    LiveAssistView(
                        viewModel: LiveAssistViewModel(
                            cameraService: dependencies.cameraService,
                            recommendationService: dependencies.recommendationService,
                            settingsService: dependencies.settingsService
                        )
                    )
                case .gearProfiles:
                    GearProfilesView(
                        viewModel: GearProfilesViewModel(
                            repository: dependencies.gearProfileRepository,
                            settingsService: dependencies.settingsService
                        )
                    )
                case .settings:
                    SettingsView(
                        viewModel: SettingsViewModel(settingsService: dependencies.settingsService)
                    )
                }
            }
        }
    }
}
