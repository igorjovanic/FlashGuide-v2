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
    @State private var isEditingCustomDistance = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case subjectDistance
    }

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
                    VStack(alignment: .leading, spacing: 28) {
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
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    focusedField = nil
                    isEditingCustomDistance = false
                }
            }
        }
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
        .onChange(of: focusedField) { _, newValue in
            if newValue != .subjectDistance {
                isEditingCustomDistance = false
            }
        }
    }

    private var selectedGearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Selected Gear")

            VStack(spacing: 0) {
                pickerRow(
                    title: "Camera",
                    selection: $viewModel.selectedCameraBodyID,
                    selectedLabel: selectedLabel(
                        for: viewModel.selectedCameraBodyID,
                        items: viewModel.availableCameraBodies.map {
                            SelectionItem(
                                id: $0.id,
                                label: "\($0.brand) \($0.model)"
                            )
                        }
                    ),
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
                    selectedLabel: selectedLabel(
                        for: viewModel.selectedLensID,
                        items: viewModel.availableLenses.map {
                            SelectionItem(
                                id: $0.id,
                                label: "\($0.brand) \($0.model)"
                            )
                        }
                    ),
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
                    selectedLabel: selectedLabel(
                        for: viewModel.selectedFlashUnitID,
                        items: viewModel.availableFlashUnits.map {
                            SelectionItem(
                                id: $0.id,
                                label: "\($0.brand) \($0.model)"
                            )
                        }
                    ),
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
                .padding(.horizontal, 2)
        }
    }

    private var sceneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Scene")

            VStack(spacing: 0) {
                distanceRow

                dividerLine

                pickerRow(
                    title: "Scene Type",
                    selection: $viewModel.sceneKindOverride,
                    selectedLabel: selectedLabel(
                        for: viewModel.sceneKindOverride,
                        items: [
                            SelectionItem(id: AmbientSceneKind.daylight, label: "Daylight"),
                            SelectionItem(id: AmbientSceneKind.goldenHour, label: "Golden Hour"),
                            SelectionItem(id: AmbientSceneKind.indoorLowLight, label: "Indoor Low Light"),
                            SelectionItem(id: AmbientSceneKind.night, label: "Night")
                        ]
                    ),
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
                    selectedLabel: selectedLabel(
                        for: viewModel.ambientPreference,
                        items: AmbientPreference.allCases.map {
                            SelectionItem(id: $0, label: $0.displayName)
                        }
                    ),
                    items: AmbientPreference.allCases.map {
                        SelectionItem(id: $0, label: $0.displayName)
                    }
                )
            }
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("Enter distance in meters, choose the scene type, and then decide how much ambient light you want to preserve.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)
        }
    }

    private var distanceRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text("Subject Distance")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 12) {
                distanceStepButton(systemName: "minus") {
                    isEditingCustomDistance = false
                    focusedField = nil
                    viewModel.decrementSubjectDistance()
                }

                Group {
                    if isEditingCustomDistance {
                        TextField("Meters", text: $viewModel.subjectDistanceText)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .subjectDistance)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.primary)
                            .onChange(of: viewModel.subjectDistanceText) { _, newValue in
                                viewModel.sanitizeSubjectDistance(newValue)
                            }
                    } else {
                        Text(viewModel.formattedSubjectDistance)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    isEditingCustomDistance = true
                    focusedField = .subjectDistance
                }

                distanceStepButton(systemName: "plus") {
                    isEditingCustomDistance = false
                    focusedField = nil
                    viewModel.incrementSubjectDistance()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.validationErrors, id: \.self) { error in
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                viewModel.generateRecommendation()
            } label: {
                Text("Calculate")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityLabel("Calculate recommendation")

            Text("Use this as a starting point, then refine after a test frame.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
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
                }
                .padding(18)
                .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                Text("Select saved gear, enter a subject distance, choose the scene type and light balance, then tap Calculate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private func pickerRow<SelectionValue: Hashable>(
        title: String,
        selection: Binding<SelectionValue>,
        selectedLabel: String,
        items: [SelectionItem<SelectionValue>]
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Menu {
                ForEach(items) { item in
                    Button(item.label) {
                        selection.wrappedValue = item.id
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedLabel)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 170, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .tint(.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private func selectedLabel<SelectionValue: Hashable>(
        for selection: SelectionValue,
        items: [SelectionItem<SelectionValue>]
    ) -> String {
        items.first(where: { $0.id == selection })?.label ?? ""
    }

    private func resultMetricRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }

    private func distanceStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(
                    Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private var dividerLine: some View {
        Divider()
            .padding(.leading, 18)
    }

    private var screenBackground: Color {
        Color(.systemBackground)
    }

    private var cardBackground: Color {
        Color(.secondarySystemBackground)
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
