//
//  SettingsView.swift
//  FlashGuideV2
//

import SwiftUI

struct SettingsView: View {
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
        }
        .navigationTitle("Settings")
    }
}
