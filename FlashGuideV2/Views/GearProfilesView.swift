//
//  GearProfilesView.swift
//  FlashGuideV2
//

import SwiftData
import SwiftUI

struct GearProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CameraBody.createdAt) private var cameraBodies: [CameraBody]
    @Query(sort: \Lens.createdAt) private var lenses: [Lens]
    @Query(sort: \FlashUnit.createdAt) private var flashUnits: [FlashUnit]
    @StateObject private var viewModel: GearProfilesViewModel
    @State private var addSheet: AddGearSheet?

    init(viewModel: GearProfilesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _cameraBodies = Query(sort: \CameraBody.createdAt)
        _lenses = Query(sort: \Lens.createdAt)
        _flashUnits = Query(sort: \FlashUnit.createdAt)
    }

    var body: some View {
        Group {
            if cameraBodies.isEmpty && lenses.isEmpty && flashUnits.isEmpty {
                ContentUnavailableView(
                    "No Gear Profiles",
                    systemImage: "camera.aperture",
                    description: Text("Add a camera body, lens, or flash unit to get started.")
                )
            } else {
                List {
                    defaultSetupSection
                    cameraBodiesSection
                    lensesSection
                    flashUnitsSection
                }
            }
        }
        .navigationTitle("Gear Profiles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Add") {
                    Button("Camera Body") { addSheet = .cameraBody }
                    Button("Lens") { addSheet = .lens }
                    Button("Flash Unit") { addSheet = .flashUnit }
                }
            }
        }
        .sheet(item: $addSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .cameraBody:
                    CameraBodyEditorView(
                        cameraBody: viewModel.makeCameraBody(),
                        title: "New Camera Body",
                        isNewRecord: true,
                        onSave: { cameraBody in
                            try viewModel.save(cameraBody, using: modelContext)
                        }
                    )
                case .lens:
                    LensEditorView(
                        lens: viewModel.makeLens(),
                        title: "New Lens",
                        isNewRecord: true,
                        onSave: { lens in
                            try viewModel.save(lens, using: modelContext)
                        }
                    )
                case .flashUnit:
                    FlashUnitEditorView(
                        title: "New Flash Unit",
                        flashUnit: viewModel.makeFlashUnit(),
                        isNewRecord: true,
                        onSave: { flashUnit in
                            try viewModel.save(flashUnit, using: modelContext)
                        }
                    )
                }
            }
        }
    }

    private var defaultSetupSection: some View {
        Section("Default Setup") {
            Picker("Camera Body", selection: defaultCameraBodyBinding) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(cameraBodies, id: \.id) { cameraBody in
                    Text("\(cameraBody.brand) \(cameraBody.model)").tag(Optional(cameraBody.id))
                }
            }

            Picker("Lens", selection: defaultLensBinding) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(lenses, id: \.id) { lens in
                    Text("\(lens.brand) \(lens.model)").tag(Optional(lens.id))
                }
            }

            Picker("Flash Unit", selection: defaultFlashUnitBinding) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(flashUnits, id: \.id) { flashUnit in
                    Text("\(flashUnit.brand) \(flashUnit.model)").tag(Optional(flashUnit.id))
                }
            }
        }
    }

    private var cameraBodiesSection: some View {
        Section("Camera Bodies") {
            if cameraBodies.isEmpty {
                Text("No camera bodies saved.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(cameraBodies) { cameraBody in
                    NavigationLink {
                        CameraBodyEditorView(
                            cameraBody: cameraBody,
                            title: "Edit Camera Body",
                            isNewRecord: false,
                            onSave: { _ in
                                try modelContext.save()
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(cameraBody.brand) \(cameraBody.model)")
                            Text("Sync \(cameraBody.flashSyncSpeed) • ISO \(cameraBody.minISO)-\(cameraBody.maxISO)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            try? viewModel.delete(cameraBody, using: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var lensesSection: some View {
        Section("Lenses") {
            if lenses.isEmpty {
                Text("No lenses saved.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(lenses) { lens in
                    NavigationLink {
                        LensEditorView(
                            lens: lens,
                            title: "Edit Lens",
                            isNewRecord: false,
                            onSave: { _ in
                                try modelContext.save()
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(lens.brand) \(lens.model)")
                            Text("\(lens.focalLengthDescription ?? "Prime") • f/\(lens.minAperture.formatted(.number.precision(.fractionLength(1))))-f/\(lens.maxAperture.formatted(.number.precision(.fractionLength(1))))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            try? viewModel.delete(lens, using: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var flashUnitsSection: some View {
        Section("Flash Units") {
            if flashUnits.isEmpty {
                Text("No flash units saved.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(flashUnits) { flashUnit in
                    NavigationLink {
                        FlashUnitEditorView(
                            title: "Edit Flash Unit",
                            flashUnit: flashUnit,
                            isNewRecord: false,
                            onSave: { _ in
                                try modelContext.save()
                            }
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(flashUnit.brand) \(flashUnit.model)")
                            Text("GN \(flashUnit.guideNumber.formatted(.number.precision(.fractionLength(0)))) @ ISO \(flashUnit.guideNumberISOReference)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            try? viewModel.delete(flashUnit, using: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var defaultCameraBodyBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.defaultCameraBodyID },
            set: { viewModel.defaultCameraBodyID = $0 }
        )
    }

    private var defaultLensBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.defaultLensID },
            set: { viewModel.defaultLensID = $0 }
        )
    }

    private var defaultFlashUnitBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.defaultFlashUnitID },
            set: { viewModel.defaultFlashUnitID = $0 }
        )
    }
}

private enum AddGearSheet: String, Identifiable {
    case cameraBody
    case lens
    case flashUnit

    var id: String { rawValue }
}

private struct CameraBodyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var cameraBody: CameraBody
    @State private var cameraName: String
    @State private var validationMessage: String?
    let title: String
    let isNewRecord: Bool
    let onSave: (CameraBody) throws -> Void

    init(
        cameraBody: CameraBody,
        title: String,
        isNewRecord: Bool,
        onSave: @escaping (CameraBody) throws -> Void
    ) {
        self.cameraBody = cameraBody
        self.title = title
        self.isNewRecord = isNewRecord
        self.onSave = onSave
        _cameraName = State(initialValue: [cameraBody.brand, cameraBody.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " "))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Camera")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("Eg. Sony a7 III", text: $cameraName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Exposure Limits")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        syncSpeedRow
                        editorDivider
                        isoRow(title: "Minimum ISO", value: $cameraBody.minISO)
                        editorDivider
                        isoRow(title: "Maximum ISO", value: $cameraBody.maxISO)
                    }
                    .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Enter the shutter denominator for sync speed, plus the camera's supported ISO range.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else {
                    Text("Example: enter 200 for a sync speed of 1/200.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    guard validate() else { return }
                    try? onSave(cameraBody)
                    dismiss()
                }
                .disabled(isSaveDisabled)
            }
        }
        .onDisappear {
            if isNewRecord == false, validate(silent: true) {
                try? onSave(cameraBody)
            }
        }
    }

    private var syncSpeedRow: some View {
        HStack(spacing: 12) {
            Text("Max Sync Speed")
                .foregroundStyle(.primary)

            Spacer()

            Text("1/")
                .foregroundStyle(.secondary)

            TextField("125", text: syncSpeedDenominatorBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private func isoRow(title: String, value: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            TextField(title, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 84)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var editorDivider: some View {
        Divider()
            .padding(.leading, 18)
    }

    private var editorCardColor: Color {
        Color(.secondarySystemBackground)
    }

    private var syncSpeedDenominatorBinding: Binding<String> {
        Binding(
            get: {
                cameraBody.flashSyncSpeed
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "1/", with: "")
            },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                cameraBody.flashSyncSpeed = digits.isEmpty ? "" : "1/\(digits)"
            }
        )
    }

    private var isSaveDisabled: Bool {
        currentValidationMessage != nil
    }

    private func validate(silent: Bool = false) -> Bool {
        let message = currentValidationMessage

        if message == nil {
            applyCameraName()
        }

        if silent == false {
            validationMessage = message
        }

        return message == nil
    }

    private var currentValidationMessage: String? {
        let trimmedName = cameraName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSync = cameraBody.flashSyncSpeed.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return "Camera name is required."
        }

        if trimmedSync.isEmpty {
            return "Flash sync speed is required."
        }

        if cameraBody.minISO <= 0 {
            return "Minimum ISO must be greater than zero."
        }

        if cameraBody.maxISO < cameraBody.minISO {
            return "Maximum ISO must be greater than or equal to minimum ISO."
        }

        return nil
    }

    private func applyCameraName() {
        let trimmedName = cameraName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmedName.split(whereSeparator: \.isWhitespace)

        guard let firstPart = parts.first else {
            cameraBody.brand = ""
            cameraBody.model = ""
            return
        }

        cameraBody.brand = String(firstPart)
        cameraBody.model = parts.dropFirst().joined(separator: " ")
    }
}

private struct LensEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var lens: Lens
    @State private var validationMessage: String?
    let title: String
    let isNewRecord: Bool
    let onSave: (Lens) throws -> Void

    var body: some View {
        Form {
            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Identity") {
                TextField("Brand", text: $lens.brand)
                TextField("Model", text: $lens.model)
                TextField("Focal Length Description", text: focalLengthBinding)
            }

            Section("Optics") {
                TextField("Minimum Aperture", value: $lens.minAperture, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                TextField("Maximum Aperture", value: $lens.maxAperture, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                Toggle("Variable Aperture", isOn: $lens.isVariableAperture)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    guard validate() else { return }
                    try? onSave(lens)
                    dismiss()
                }
            }
        }
        .onDisappear {
            if isNewRecord == false, validate(silent: true) {
                try? onSave(lens)
            }
        }
    }

    private var focalLengthBinding: Binding<String> {
        Binding(
            get: { lens.focalLengthDescription ?? "" },
            set: { lens.focalLengthDescription = $0.isEmpty ? nil : $0 }
        )
    }

    private func validate(silent: Bool = false) -> Bool {
        let trimmedBrand = lens.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = lens.model.trimmingCharacters(in: .whitespacesAndNewlines)

        let message: String?

        if trimmedBrand.isEmpty {
            message = "Brand is required."
        } else if trimmedModel.isEmpty {
            message = "Model is required."
        } else if lens.minAperture <= 0 {
            message = "Minimum aperture must be greater than zero."
        } else if lens.maxAperture < lens.minAperture {
            message = "Maximum aperture must be greater than or equal to minimum aperture."
        } else {
            message = nil
        }

        if silent == false {
            validationMessage = message
        }

        return message == nil
    }
}

private struct FlashUnitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var flashUnit: FlashUnit
    @State private var powerStepsText: String
    @State private var validationMessage: String?
    let title: String
    let isNewRecord: Bool
    let onSave: (FlashUnit) throws -> Void

    init(
        title: String,
        flashUnit: FlashUnit,
        isNewRecord: Bool,
        onSave: @escaping (FlashUnit) throws -> Void
    ) {
        self.title = title
        self.flashUnit = flashUnit
        self.isNewRecord = isNewRecord
        self.onSave = onSave
        _powerStepsText = State(initialValue: flashUnit.supportedPowerSteps.joined(separator: ", "))
    }

    var body: some View {
        Form {
            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Identity") {
                TextField("Brand", text: $flashUnit.brand)
                TextField("Model", text: $flashUnit.model)
            }

            Section("Output") {
                TextField("Guide Number", value: $flashUnit.guideNumber, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.decimalPad)
                TextField("ISO Reference", value: $flashUnit.guideNumberISOReference, format: .number)
                    .keyboardType(.numberPad)
                TextField("Power Steps", text: $powerStepsText, axis: .vertical)
                TextField("Notes", text: $flashUnit.notes, axis: .vertical)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    guard validate() else { return }
                    flashUnit.supportedPowerSteps = parsedPowerSteps
                    try? onSave(flashUnit)
                    dismiss()
                }
            }
        }
        .onDisappear {
            if validate(silent: true) {
                flashUnit.supportedPowerSteps = parsedPowerSteps
            }
            if isNewRecord == false, validate(silent: true) {
                try? onSave(flashUnit)
            }
        }
    }

    private var parsedPowerSteps: [String] {
        powerStepsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func validate(silent: Bool = false) -> Bool {
        let trimmedBrand = flashUnit.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = flashUnit.model.trimmingCharacters(in: .whitespacesAndNewlines)

        let message: String?

        if trimmedBrand.isEmpty {
            message = "Brand is required."
        } else if trimmedModel.isEmpty {
            message = "Model is required."
        } else if flashUnit.guideNumber <= 0 {
            message = "Guide number must be greater than zero."
        } else if flashUnit.guideNumberISOReference <= 0 {
            message = "Guide number ISO reference must be greater than zero."
        } else if parsedPowerSteps.isEmpty {
            message = "At least one flash power step is required."
        } else {
            message = nil
        }

        if silent == false {
            validationMessage = message
        }

        return message == nil
    }
}
