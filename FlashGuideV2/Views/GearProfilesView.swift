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

    init(viewModel: GearProfilesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _cameraBodies = Query(sort: \CameraBody.createdAt)
        _lenses = Query(sort: \Lens.createdAt)
        _flashUnits = Query(sort: \FlashUnit.createdAt)
    }

    var body: some View {
        List {
            Section("Camera Bodies") {
                if cameraBodies.isEmpty {
                    Text("No camera bodies saved.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(cameraBodies) { body in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(body.name)
                            Text("Sync 1/\(body.syncSpeedDenominator) • ISO \(body.isoMin)-\(body.isoMax)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Lenses") {
                if lenses.isEmpty {
                    Text("No lenses saved.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(lenses) { lens in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lens.name)
                            Text("\(lens.focalLengthDescription) • f/\(lens.apertureMin, format: .number.precision(.fractionLength(1)))-f/\(lens.apertureMax, format: .number.precision(.fractionLength(1)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Flash Units") {
                if flashUnits.isEmpty {
                    Text("No flash units saved.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(flashUnits) { flashUnit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flashUnit.name)
                            Text("GN \(flashUnit.guideNumber, format: .number.precision(.fractionLength(0))) • \(flashUnit.powerLevels.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Gear Profiles")
        .onAppear {
            viewModel.seedIfNeeded(using: modelContext)
        }
    }
}
