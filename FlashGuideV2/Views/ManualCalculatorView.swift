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
            Section("Selected Gear") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.sceneInput.selectedCameraBody.brand) \(viewModel.sceneInput.selectedCameraBody.model)")
                    Text("Sync \(viewModel.sceneInput.selectedCameraBody.flashSyncSpeed) • ISO \(viewModel.sceneInput.selectedCameraBody.minISO)-\(viewModel.sceneInput.selectedCameraBody.maxISO)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.sceneInput.selectedLens.brand) \(viewModel.sceneInput.selectedLens.model)")
                    Text(lensSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.sceneInput.selectedFlashUnit.brand) \(viewModel.sceneInput.selectedFlashUnit.model)")
                    Text("GN \(viewModel.sceneInput.selectedFlashUnit.guideNumber, format: .number.precision(.fractionLength(0))) @ ISO \(viewModel.sceneInput.selectedFlashUnit.guideNumberISOReference)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.sceneInput.selectedFlashUnit.supportedPowerSteps.joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

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

                LabeledContent("Depth Estimate") {
                    TextField(
                        "Optional",
                        value: optionalNumberBinding(for: \.depthEstimate),
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }

                LabeledContent("Manual Override") {
                    TextField(
                        "Optional",
                        value: optionalNumberBinding(for: \.manualDistanceOverride),
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }

                Picker("Ambient Preference", selection: $viewModel.sceneInput.ambientPreference) {
                    ForEach(AmbientPreference.allCases) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }

                LabeledContent("Ambient Meter") {
                    TextField(
                        "Optional",
                        value: optionalNumberBinding(for: \.ambientMeterValue),
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }

            Section("Live Assist State") {
                Toggle("Depth Available", isOn: $viewModel.sceneInput.isDepthAvailable)
                Toggle("Subject Selection Locked", isOn: $viewModel.sceneInput.isSubjectSelectionLocked)

                if let selectedTapPoint = viewModel.sceneInput.selectedTapPoint {
                    DetailRow(
                        title: "Tap Point",
                        value: "\(selectedTapPoint.normalizedX.formatted(.number.precision(.fractionLength(2)))), \(selectedTapPoint.normalizedY.formatted(.number.precision(.fractionLength(2))))"
                    )
                } else {
                    Text("No tap point selected.")
                        .foregroundStyle(.secondary)
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
                    DetailRow(title: "Shutter", value: recommendation.shutterSpeed)
                    DetailRow(title: "Aperture", value: recommendation.aperture)
                    DetailRow(title: "ISO", value: recommendation.iso)
                    DetailRow(title: "Flash Power", value: recommendation.flashPowerStep)
                    DetailRow(title: "Confidence", value: recommendation.confidenceScore.formatted(.percent.precision(.fractionLength(0))))
                    ForEach(recommendation.reasoning, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(recommendation.warnings, id: \.self) { warning in
                        Text(warning)
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Manual Calculator")
    }

    private var lensSummary: String {
        let lens = viewModel.sceneInput.selectedLens
        let focalLength = lens.focalLengthDescription ?? "Prime"
        let apertureRange = "f/\(lens.minAperture.formatted(.number.precision(.fractionLength(1))))-f/\(lens.maxAperture.formatted(.number.precision(.fractionLength(1))))"
        let variableFlag = lens.isVariableAperture ? "Variable Aperture" : "Constant Aperture"
        return "\(focalLength) • \(apertureRange) • \(variableFlag)"
    }

    private func optionalNumberBinding(for keyPath: WritableKeyPath<SceneInput, Double?>) -> Binding<Double> {
        Binding(
            get: { viewModel.sceneInput[keyPath: keyPath] ?? 0 },
            set: { newValue in
                viewModel.sceneInput[keyPath: keyPath] = newValue == 0 ? nil : newValue
            }
        )
    }
}
