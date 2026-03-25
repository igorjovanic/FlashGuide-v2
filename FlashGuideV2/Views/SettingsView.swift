//
//  SettingsView.swift
//  FlashGuideV2
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appDependencies) private var dependencies
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Live Assist") {
                Toggle("Enable Depth Assistance", isOn: $viewModel.depthAssistanceEnabled)
                    .onChange(of: viewModel.depthAssistanceEnabled) { _, _ in
                        viewModel.persist()
                    }
            }

            Section("Units") {
                Picker("Distance Unit", selection: $viewModel.distanceUnit) {
                    ForEach(DistanceUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .onChange(of: viewModel.distanceUnit) { _, _ in
                    viewModel.persist()
                }
            }

            Section("Defaults") {
                NavigationLink("Manage Default Gear Setup") {
                    GearProfilesView(
                        viewModel: GearProfilesViewModel(
                            repository: dependencies.gearProfileRepository,
                            settingsService: dependencies.settingsService
                        )
                    )
                }
            }
        }
        .navigationTitle("Settings")
    }
}
