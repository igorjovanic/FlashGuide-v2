//
//  LiveAssistView.swift
//  FlashGuideV2
//

import SwiftUI

struct LiveAssistView: View {
    @StateObject private var viewModel: LiveAssistViewModel

    init(viewModel: LiveAssistViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CameraPreviewPlaceholderView()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Depth Support")
                        .font(.headline)
                    Text(viewModel.depthSupportState.displayName)
                        .foregroundStyle(.secondary)

                    if let tapSelection = viewModel.tapSelection {
                        Text("Selected Point: \(tapSelection.normalizedX, format: .number.precision(.fractionLength(2))), \(tapSelection.normalizedY, format: .number.precision(.fractionLength(2)))")
                            .font(.subheadline)
                    } else {
                        Text("No subject point selected yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Simulate Subject Tap") {
                    viewModel.selectPoint(x: 0.5, y: 0.5)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Live Assist")
        .navigationBarTitleDisplayMode(.inline)
    }
}
