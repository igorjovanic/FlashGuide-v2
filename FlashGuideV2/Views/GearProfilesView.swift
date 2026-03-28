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
    let cameraBody: CameraBody
    @State private var cameraName: String
    @State private var syncSpeedDenominator: String
    @State private var minISOText: String
    @State private var maxISOText: String
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
        _syncSpeedDenominator = State(initialValue: cameraBody.flashSyncSpeed
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "1/", with: ""))
        _minISOText = State(initialValue: cameraBody.minISO > 0 ? String(cameraBody.minISO) : "")
        _maxISOText = State(initialValue: cameraBody.maxISO > 0 ? String(cameraBody.maxISO) : "")
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
                        integerRow(title: "Minimum ISO", text: $minISOText)
                        editorDivider
                        integerRow(title: "Maximum ISO", text: $maxISOText)
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

            TextField("125", text: digitsOnlyBinding(for: $syncSpeedDenominator))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private func integerRow(title: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            TextField(title, text: digitsOnlyBinding(for: text))
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

    private func digitsOnlyBinding(for text: Binding<String>) -> Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { newValue in
                text.wrappedValue = newValue.filter(\.isNumber)
            }
        )
    }

    private var isSaveDisabled: Bool {
        currentValidationMessage != nil
    }

    private func validate(silent: Bool = false) -> Bool {
        let message = currentValidationMessage

        if message == nil {
            applyCameraBodyDraft()
        }

        if silent == false {
            validationMessage = message
        }

        return message == nil
    }

    private var currentValidationMessage: String? {
        let trimmedName = cameraName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSync = syncSpeedDenominator.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedMinISO = Int(minISOText.trimmingCharacters(in: .whitespacesAndNewlines))
        let parsedMaxISO = Int(maxISOText.trimmingCharacters(in: .whitespacesAndNewlines))

        if trimmedName.isEmpty {
            return "Camera name is required."
        }

        if trimmedSync.isEmpty {
            return "Flash sync speed is required."
        }

        guard let parsedMinISO else {
            return "Minimum ISO must be greater than zero."
        }

        if parsedMinISO <= 0 {
            return "Minimum ISO must be greater than zero."
        }

        guard let parsedMaxISO else {
            return "Maximum ISO must be greater than or equal to minimum ISO."
        }

        if parsedMaxISO < parsedMinISO {
            return "Maximum ISO must be greater than or equal to minimum ISO."
        }

        return nil
    }

    private func applyCameraBodyDraft() {
        let parsedMinISO = Int(minISOText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? cameraBody.minISO
        let parsedMaxISO = Int(maxISOText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? cameraBody.maxISO

        cameraBody.flashSyncSpeed = "1/\(syncSpeedDenominator)"
        cameraBody.minISO = parsedMinISO
        cameraBody.maxISO = parsedMaxISO

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
    let lens: Lens
    @State private var lensName: String
    @State private var minApertureText: String
    @State private var maxApertureText: String
    @State private var validationMessage: String?
    let title: String
    let isNewRecord: Bool
    let onSave: (Lens) throws -> Void

    init(
        lens: Lens,
        title: String,
        isNewRecord: Bool,
        onSave: @escaping (Lens) throws -> Void
    ) {
        self.lens = lens
        self.title = title
        self.isNewRecord = isNewRecord
        self.onSave = onSave
        _lensName = State(initialValue: [
            lens.focalLengthDescription,
            [lens.brand, lens.model]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
                .joined(separator: " ")
        ]
        .compactMap { value in
            guard let value else { return nil }
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue.isEmpty ? nil : trimmedValue
        }
        .joined(separator: " "))
        _minApertureText = State(initialValue: Self.apertureText(for: lens.minAperture))
        _maxApertureText = State(initialValue: Self.apertureText(for: lens.maxAperture))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lens")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("Eg. 50mm f/1.8", text: $lensName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Aperture Range")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        apertureRow(title: "Widest Aperture", text: $minApertureText)
                        editorDivider
                        apertureRow(title: "Narrowest Aperture", text: $maxApertureText)
                    }
                    .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Enter the widest and narrowest f-stops this lens can use.")
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
                    Text("Use numeric f-stop values such as 1.8, 2.8, 8, or 16.")
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
                    try? onSave(lens)
                    dismiss()
                }
                .disabled(isSaveDisabled)
            }
        }
        .onDisappear {
            if isNewRecord == false, validate(silent: true) {
                try? onSave(lens)
            }
        }
    }

    private func apertureRow(title: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Text("f/")
                .foregroundStyle(.secondary)

            TextField(title, text: apertureBinding(for: text))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
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

    private func apertureBinding(for text: Binding<String>) -> Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { newValue in
                var filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "," }

                if let commaIndex = filtered.firstIndex(of: ",") {
                    filtered.replaceSubrange(commaIndex...commaIndex, with: ".")
                }

                let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
                if parts.count > 2 {
                    filtered = parts.prefix(2).joined(separator: ".")
                }

                if let dotIndex = filtered.firstIndex(of: ".") {
                    let fractionalStart = filtered.index(after: dotIndex)
                    let fractionalDigits = filtered[fractionalStart...].filter(\.isNumber)
                    filtered = String(filtered[..<fractionalStart]) + fractionalDigits.prefix(1)
                }

                text.wrappedValue = filtered
            }
        )
    }

    private var isSaveDisabled: Bool {
        currentValidationMessage != nil
    }

    private func validate(silent: Bool = false) -> Bool {
        let message = currentValidationMessage

        if message == nil {
            applyLensDraft()
        }

        if silent == false {
            validationMessage = message
        }

        return message == nil
    }

    private var currentValidationMessage: String? {
        let trimmedName = lensName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedMinAperture = parseAperture(minApertureText)
        let parsedMaxAperture = parseAperture(maxApertureText)

        if trimmedName.isEmpty {
            return "Lens name is required."
        }

        guard let parsedMinAperture else {
            return "Widest aperture must be greater than zero."
        }

        if parsedMinAperture <= 0 {
            return "Widest aperture must be greater than zero."
        }

        guard let parsedMaxAperture else {
            return "Narrowest aperture must be greater than or equal to widest aperture."
        }

        if parsedMaxAperture < parsedMinAperture {
            return "Narrowest aperture must be greater than or equal to widest aperture."
        }

        return nil
    }

    private func applyLensDraft() {
        lens.minAperture = parseAperture(minApertureText) ?? lens.minAperture
        lens.maxAperture = parseAperture(maxApertureText) ?? lens.maxAperture

        let trimmedName = lensName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            lens.brand = ""
            lens.model = ""
            lens.focalLengthDescription = nil
            return
        }

        let parts = trimmedName.split(whereSeparator: \.isWhitespace)
        let focalToken = parts.first(where: { $0.localizedCaseInsensitiveContains("mm") })

        lens.focalLengthDescription = focalToken.map(String.init)

        if let focalToken {
            let focalString = String(focalToken)
            let remainder = trimmedName.replacingOccurrences(of: focalString, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            lens.brand = focalString
            lens.model = remainder.isEmpty ? trimmedName : remainder
            return
        }

        if let firstPart = parts.first {
            lens.brand = String(firstPart)
            lens.model = parts.dropFirst().joined(separator: " ")
        } else {
            lens.brand = ""
            lens.model = trimmedName
        }
    }

    private func parseAperture(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private static func apertureText(for value: Double) -> String {
        let roundedValue = value.rounded()
        if abs(value - roundedValue) < 0.0001 {
            return String(Int(roundedValue))
        }

        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct FlashUnitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let flashUnit: FlashUnit
    @State private var flashName: String
    @State private var guideNumberText: String
    @State private var selectedPowerSteps: Set<String>
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
        _flashName = State(initialValue: [flashUnit.brand, flashUnit.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " "))
        _guideNumberText = State(initialValue: Self.guideNumberText(for: flashUnit.guideNumber))
        _selectedPowerSteps = State(initialValue: Set(flashUnit.supportedPowerSteps))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flash")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        TextField("Eg. Godox TT685", text: $flashName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                            .padding(.bottom, 18)

                        editorDivider

                        HStack(spacing: 12) {
                            Text("Guide Number")
                                .foregroundStyle(.primary)

                            Spacer()

                            TextField("36", text: guideNumberBinding)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 72)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                    }
                    .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                Text("Guide number is stored in meters at ISO 100.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Power Steps")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        ForEach(powerStepOptions.indices, id: \.self) { index in
                            powerStepRow(step: powerStepOptions[index])

                            if index < powerStepOptions.count - 1 {
                                editorDivider
                            }
                        }
                    }
                    .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Select only the manual power steps this flash actually supports.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                }

                Text("Select the manual power steps supported by this flash unit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(editorCardColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                    try? onSave(flashUnit)
                    dismiss()
                }
                .disabled(isSaveDisabled)
            }
        }
        .onDisappear {
            if isNewRecord == false, validate(silent: true) {
                try? onSave(flashUnit)
            }
        }
    }

    private var powerStepOptions: [String] {
        ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128"]
    }

    private func powerStepRow(step: String) -> some View {
        HStack(spacing: 12) {
            Text(step)
                .foregroundStyle(.primary)

            Spacer()

            Toggle(step, isOn: powerStepBinding(for: step))
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var editorDivider: some View {
        Divider()
            .padding(.leading, 18)
    }

    private var editorCardColor: Color {
        Color(.secondarySystemBackground)
    }

    private var guideNumberBinding: Binding<String> {
        Binding(
            get: { guideNumberText },
            set: { newValue in
                var filtered = newValue.filter { $0.isNumber || $0 == "." || $0 == "," }

                if let commaIndex = filtered.firstIndex(of: ",") {
                    filtered.replaceSubrange(commaIndex...commaIndex, with: ".")
                }

                let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
                if parts.count > 2 {
                    filtered = parts.prefix(2).joined(separator: ".")
                }

                if let dotIndex = filtered.firstIndex(of: ".") {
                    let fractionalStart = filtered.index(after: dotIndex)
                    let fractionalDigits = filtered[fractionalStart...].filter(\.isNumber)
                    filtered = String(filtered[..<fractionalStart]) + fractionalDigits.prefix(1)
                }

                guideNumberText = filtered
            }
        )
    }

    private func powerStepBinding(for step: String) -> Binding<Bool> {
        Binding(
            get: { selectedPowerSteps.contains(step) },
            set: { isEnabled in
                if isEnabled {
                    selectedPowerSteps.insert(step)
                } else {
                    selectedPowerSteps.remove(step)
                }
            }
        )
    }

    private var isSaveDisabled: Bool {
        currentValidationMessage != nil
    }

    private func validate(silent: Bool = false) -> Bool {
        let message = currentValidationMessage

        if message == nil {
            applyFlashDraft()
        }

        return message == nil
    }

    private var currentValidationMessage: String? {
        let trimmedName = flashName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedGuideNumber = Double(guideNumberText.replacingOccurrences(of: ",", with: "."))

        if trimmedName.isEmpty {
            return "Flash name is required."
        }

        guard let parsedGuideNumber else {
            return "Guide number must be greater than zero."
        }

        if parsedGuideNumber <= 0 {
            return "Guide number must be greater than zero."
        }

        if selectedPowerSteps.isEmpty {
            return "At least one flash power step is required."
        }

        return nil
    }

    private func applyFlashDraft() {
        flashUnit.guideNumber = Double(guideNumberText.replacingOccurrences(of: ",", with: ".")) ?? flashUnit.guideNumber
        flashUnit.guideNumberISOReference = 100
        flashUnit.supportedPowerSteps = powerStepOptions.filter { selectedPowerSteps.contains($0) }
        flashUnit.notes = ""

        let trimmedName = flashName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmedName.split(whereSeparator: \.isWhitespace)

        guard let firstPart = parts.first else {
            flashUnit.brand = ""
            flashUnit.model = ""
            return
        }

        flashUnit.brand = String(firstPart)
        flashUnit.model = parts.dropFirst().joined(separator: " ")
    }

    private static func guideNumberText(for value: Double) -> String {
        let roundedValue = value.rounded()
        if abs(value - roundedValue) < 0.0001 {
            return String(Int(roundedValue))
        }

        return value.formatted(.number.precision(.fractionLength(1)))
    }
}
