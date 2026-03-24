//
//  ManualCalculatorView.swift
//  FlashGuideV2
//

import SwiftUI

struct ManualCalculatorView: View {
    @StateObject private var viewModel: ManualCalculatorViewModel

    init(viewModel: ManualCalculatorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Scene Input") {
                LabeledContent("Subject Distance") {
                    TextField(
                        "Meters",
                        value: $viewModel.sceneInput.subjectDistanceMeters,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }

                LabeledContent("Ambient EV") {
                    TextField(
                        "EV",
                        value: $viewModel.sceneInput.ambientEV,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }

            Section {
                Button("Generate Recommendation") {
                    viewModel.generateRecommendation()
                }
                .frame(maxWidth: .infinity)
            }

            if let recommendation = viewModel.recommendation {
                Section("Recommendation") {
                    DetailRow(title: "Shutter", value: recommendation.shutterSpeedDescription)
                    DetailRow(title: "Aperture", value: recommendation.apertureDescription)
                    DetailRow(title: "ISO", value: recommendation.isoDescription)
                    DetailRow(title: "Flash Power", value: recommendation.flashPowerDescription)
                    Text(recommendation.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Manual Calculator")
    }
}
