//
//  ManualCalculatorView.swift
//  FlashGuideV2
//

import SwiftData
import SwiftUI

struct ManualCalculatorView: View {
    @Environment(\.colorScheme) private var colorScheme

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
        Group {
            if viewModel.availableCameraBodies.isEmpty || viewModel.availableLenses.isEmpty || viewModel.availableFlashUnits.isEmpty {
                ContentUnavailableView(
                    "No Gear Available",
                    systemImage: "camera.metering.unknown",
                    description: Text("Add your camera body, lens, and flash profiles before calculating recommendations.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleSection
                        selectedGearSection
                        sceneSection

                        if !viewModel.validationErrors.isEmpty {
                            validationSection
                        }

                        actionSection
                        resultSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .background(screenBackground)
            }
        }
        .navigationTitle("Manual Calculator")
        .navigationBarTitleDisplayMode(.inline)
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

    private var titleSection: some View {
        Text("New Calculation")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)
    }

    private var selectedGearSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Selected Gear")

            VStack(spacing: 0) {
                pickerRow(
                    title: "Camera",
                    selection: $viewModel.selectedCameraBodyID,
                    items: viewModel.availableCameraBodies.map {
                        SelectionItem(
                            id: $0.id,
                            label: "\($0.brand) \($0.model)"
                        )
                    }
                )

                dividerLine

                pickerRow(
                    title: "Lens",
                    selection: $viewModel.selectedLensID,
                    items: viewModel.availableLenses.map {
                        SelectionItem(
                            id: $0.id,
                            label: "\($0.brand) \($0.model)"
                        )
                    }
                )

                dividerLine

                pickerRow(
                    title: "Flash",
                    selection: $viewModel.selectedFlashUnitID,
                    items: viewModel.availableFlashUnits.map {
                        SelectionItem(
                            id: $0.id,
                            label: "\($0.brand) \($0.model)"
                        )
                    }
                )
            }
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Pick one saved camera, lens, and flash profile for this calculation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
        }
    }

    private var sceneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Scene")

            VStack(spacing: 0) {
                distanceRow

                dividerLine

                pickerRow(
                    title: "Scene Type",
                    selection: $viewModel.sceneKindOverride,
                    items: [
                        SelectionItem(id: AmbientSceneKind.daylight, label: "Daylight"),
                        SelectionItem(id: AmbientSceneKind.goldenHour, label: "Golden Hour"),
                        SelectionItem(id: AmbientSceneKind.indoorLowLight, label: "Indoor Low Light"),
                        SelectionItem(id: AmbientSceneKind.night, label: "Night")
                    ]
                )

                dividerLine

                pickerRow(
                    title: "Light Balance",
                    selection: $viewModel.ambientPreference,
                    items: AmbientPreference.allCases.map {
                        SelectionItem(id: $0, label: $0.displayName)
                    }
                )
            }
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Enter distance in meters, choose the scene type, and then decide how much ambient light you want to preserve.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
        }
    }

    private var distanceRow: some View {
        HStack(spacing: 12) {
            Text("Subject Distance")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(primaryText)

            Spacer()

            TextField("Meters", text: $viewModel.subjectDistanceText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(secondaryValueText)
                .onChange(of: viewModel.subjectDistanceText) { _, newValue in
                    viewModel.sanitizeSubjectDistance(newValue)
                }

            Text("m")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.validationErrors, id: \.self) { error in
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(validationText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(validationBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var actionSection: some View {
        Button {
            viewModel.generateRecommendation()
        } label: {
            Text("Calculate")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("Calculate recommendation")
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Result")

            if let recommendation = viewModel.recommendation {
                VStack(alignment: .leading, spacing: 14) {
                    resultMetricRow("Shutter", recommendation.shutterSpeed)
                    resultMetricRow("Aperture", recommendation.aperture)
                    resultMetricRow("ISO", recommendation.iso)
                    resultMetricRow("Flash Power", recommendation.flashPowerStep)
                    resultMetricRow(
                        "Confidence",
                        recommendation.confidenceScore.formatted(.percent.precision(.fractionLength(0)))
                    )

                    Divider()

                    ForEach(recommendation.reasoning, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(recommendation.warnings, id: \.self) { warning in
                        Text(warning)
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                Text("Select saved gear, enter a subject distance, choose the scene type and light balance, then tap Calculate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
        }
    }

    private func pickerRow<SelectionValue: Hashable>(
        title: String,
        selection: Binding<SelectionValue>,
        items: [SelectionItem<SelectionValue>]
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(primaryText)

            Spacer()

            Picker(title, selection: selection) {
                ForEach(items) { item in
                    Text(item.label)
                        .tag(item.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(secondaryValueText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func resultMetricRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(primaryText)
            Spacer()
            Text(value)
                .foregroundStyle(secondaryValueText)
        }
        .font(.system(size: 16, weight: .medium))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
    }

    private var dividerLine: some View {
        Divider()
            .padding(.leading, 16)
    }

    private var screenBackground: Color {
        colorScheme == .dark ? Color(.systemGroupedBackground) : Color(.systemGroupedBackground)
    }

    private var cardBackground: Color {
        Color(.secondarySystemBackground)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var secondaryValueText: Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : Color.secondary
    }

    private var validationBackground: Color {
        colorScheme == .dark ? Color.red.opacity(0.16) : Color.red.opacity(0.10)
    }

    private var validationText: Color {
        colorScheme == .dark ? Color.red.opacity(0.92) : Color.red.opacity(0.85)
    }

    private func syncPersistedGear() {
        viewModel.updateAvailableGear(
            cameraBodies: cameraBodies,
            lenses: lenses,
            flashUnits: flashUnits
        )
    }
}

private struct SelectionItem<ID: Hashable>: Identifiable {
    let id: ID
    let label: String
}
