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
    @State private var validationMessage: String?
    let title: String
    let isNewRecord: Bool
    let onSave: (CameraBody) throws -> Void

    var body: some View {
        Form {
            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Identity") {
                TextField("Brand", text: $cameraBody.brand)
                TextField("Model", text: $cameraBody.model)
            }

            Section("Exposure Limits") {
                TextField("Flash Sync Speed", text: $cameraBody.flashSyncSpeed)
                TextField("Minimum ISO", value: $cameraBody.minISO, format: .number)
                    .keyboardType(.numberPad)
                TextField("Maximum ISO", value: $cameraBody.maxISO, format: .number)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    guard validate() else { return }
                    try? onSave(cameraBody)
                    dismiss()
                }
            }
        }
        .onDisappear {
            if isNewRecord == false, validate(silent: true) {
                try? onSave(cameraBody)
            }
        }
    }

    private func validate(silent: Bool = false) -> Bool {
        let trimmedBrand = cameraBody.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = cameraBody.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSync = cameraBody.flashSyncSpeed.trimmingCharacters(in: .whitespacesAndNewlines)

        let message: String?

        if trimmedBrand.isEmpty {
            message = "Brand is required."
        } else if trimmedModel.isEmpty {
            message = "Model is required."
        } else if trimmedSync.isEmpty {
            message = "Flash sync speed is required."
        } else if cameraBody.minISO <= 0 {
            message = "Minimum ISO must be greater than zero."
        } else if cameraBody.maxISO < cameraBody.minISO {
            message = "Maximum ISO must be greater than or equal to minimum ISO."
        } else {
            message = nil
        }

        if silent == false {
            validationMessage = message
        }

        return message == nil
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
