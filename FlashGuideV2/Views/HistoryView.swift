//
//  HistoryView.swift
//  FlashGuideV2
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.entries.isEmpty {
                ContentUnavailableView(
                    "No Recommendation History",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Recommendations from the manual calculator and live assist will appear here.")
                )
            } else {
                List(viewModel.entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.source)
                                .font(.headline)
                            Spacer()
                            Text(entry.createdAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(entry.cameraName) • \(entry.lensName) • \(entry.flashName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("\(entry.recommendation.shutterSpeed) • \(entry.recommendation.aperture) • \(entry.recommendation.iso) • \(entry.recommendation.flashPowerStep)")
                            .font(.subheadline.weight(.semibold))

                        Text("Distance: \(entry.distanceSource) • Ambient: \(entry.ambientPreference)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let warning = entry.recommendation.warnings.first {
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !viewModel.entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        viewModel.clear()
                    }
                }
            }
        }
        .onAppear {
            viewModel.reload()
        }
    }
}
