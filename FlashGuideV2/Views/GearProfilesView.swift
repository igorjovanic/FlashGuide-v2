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
                            Text("\(body.brand) \(body.model)")
                            Text("Sync \(body.flashSyncSpeed) • ISO \(body.minISO)-\(body.maxISO)")
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
                            Text("\(lens.brand) \(lens.model)")
                            Text("\(lens.focalLengthDescription ?? "Prime") • f/\(lens.minAperture, format: .number.precision(.fractionLength(1)))-f/\(lens.maxAperture, format: .number.precision(.fractionLength(1)))")
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
                            Text("\(flashUnit.brand) \(flashUnit.model)")
                            Text("GN \(flashUnit.guideNumber, format: .number.precision(.fractionLength(0))) @ ISO \(flashUnit.guideNumberISOReference) • \(flashUnit.supportedPowerSteps.joined(separator: ", "))")
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
