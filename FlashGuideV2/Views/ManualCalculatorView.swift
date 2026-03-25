//
//  ManualCalculatorView.swift
//  FlashGuideV2
//

import SwiftData
import SwiftUI

struct ManualCalculatorView: View {
    @Query(sort: \CameraBody.createdAt) private var cameraBodies: [CameraBody]
    @Query(sort: \Lens.createdAt) private var lenses: [Lens]
    @Query(sort: \FlashUnit.createdAt) private var flashUnits: [FlashUnit]
    @StateObject private var viewModel: ManualCalculatorViewModel

    init(viewModel: ManualCalculatorViewModel) {
        _cameraBodies = Query(sort: \CameraBody.createdAt)
        _lenses = Query(sort: \Lens.createdAt)
        _flashUnits = Query(sort: \FlashUnit.createdAt)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Gear Selection") {
                Picker("Camera Body", selection: $viewModel.selectedCameraBodyID) {
                    ForEach(viewModel.availableCameraBodies, id: \.id) { cameraBody in
                        Text("\(cameraBody.brand) \(cameraBody.model)").tag(cameraBody.id)
                    }
                }

                Picker("Lens", selection: $viewModel.selectedLensID) {
                    ForEach(viewModel.availableLenses, id: \.id) { lens in
                        Text("\(lens.brand) \(lens.model)").tag(lens.id)
                    }
                }

                Picker("Flash", selection: $viewModel.selectedFlashUnitID) {
                    ForEach(viewModel.availableFlashUnits, id: \.id) { flashUnit in
                        Text("\(flashUnit.brand) \(flashUnit.model)").tag(flashUnit.id)
                    }
                }
            }

            if let cameraBody = viewModel.selectedCameraBody,
               let lens = viewModel.selectedLens,
               let flashUnit = viewModel.selectedFlashUnit {
                Section("Selected Gear Details") {
                    DetailRow(title: "Sync Speed", value: cameraBody.flashSyncSpeed)
                    DetailRow(title: "ISO Range", value: "\(cameraBody.minISO)-\(cameraBody.maxISO)")
                    DetailRow(title: "Aperture Range", value: apertureRangeText(for: lens))
                    DetailRow(
                        title: "Flash Output",
                        value: "GN \(flashUnit.guideNumber.formatted(.number.precision(.fractionLength(0)))) @ ISO \(flashUnit.guideNumberISOReference)"
                    )
                    Text(flashUnit.supportedPowerSteps.joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Manual Inputs") {
                LabeledContent("Subject Distance") {
                    TextField("Meters", text: $viewModel.subjectDistanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: viewModel.subjectDistanceText) { _, newValue in
                        viewModel.sanitizeSubjectDistance(newValue)
                    }
                }

                Picker("Ambient Preference", selection: $viewModel.ambientPreference) {
                    ForEach(AmbientPreference.allCases) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }
            }

            if !viewModel.validationErrors.isEmpty {
                Section("Validation") {
                    ForEach(viewModel.validationErrors, id: \.self) { error in
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                Button("Calculate") {
                    viewModel.generateRecommendation()
                }
                .frame(maxWidth: .infinity)
            }

            Section("Result") {
                if let recommendation = viewModel.recommendation {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(title: "Shutter", value: recommendation.shutterSpeed)
                            DetailRow(title: "Aperture", value: recommendation.aperture)
                            DetailRow(title: "ISO", value: recommendation.iso)
                            DetailRow(title: "Flash Power", value: recommendation.flashPowerStep)
                            DetailRow(
                                title: "Confidence",
                                value: recommendation.confidenceScore.formatted(.percent.precision(.fractionLength(0)))
                            )

                            Divider()

                            ForEach(recommendation.reasoning, id: \.self) { item in
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(recommendation.warnings, id: \.self) { warning in
                                Label(warning, systemImage: "info.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text("Select gear, enter a subject distance, choose an ambient preference, then tap Calculate.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Manual Calculator")
        .onAppear {
            syncPersistedGear()
        }
        .onChange(of: cameraBodies) { _, _ in
            syncPersistedGear()
        }
        .onChange(of: lenses) { _, _ in
            syncPersistedGear()
        }
        .onChange(of: flashUnits) { _, _ in
            syncPersistedGear()
        }
    }

    private func apertureRangeText(for lens: Lens) -> String {
        "f/\(lens.minAperture.formatted(.number.precision(.fractionLength(1)))) - f/\(lens.maxAperture.formatted(.number.precision(.fractionLength(1))))"
    }

    private func syncPersistedGear() {
        viewModel.updateAvailableGear(
            cameraBodies: cameraBodies.isEmpty ? CameraBody.mockData : cameraBodies,
            lenses: lenses.isEmpty ? Lens.mockData : lenses,
            flashUnits: flashUnits.isEmpty ? FlashUnit.mockData : flashUnits
        )
    }
}
