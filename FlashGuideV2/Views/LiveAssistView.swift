//
//  LiveAssistView.swift
//  FlashGuideV2
//

import SwiftUI
import SwiftData

struct LiveAssistView: View {
    @StateObject private var viewModel: LiveAssistViewModel
    @Query(sort: \CameraBody.createdAt) private var cameraBodies: [CameraBody]
    @Query(sort: \Lens.createdAt) private var lenses: [Lens]
    @Query(sort: \FlashUnit.createdAt) private var flashUnits: [FlashUnit]

    init(viewModel: LiveAssistViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                previewSection

                VStack(alignment: .leading, spacing: 12) {
                    Text("Live Setup")
                        .font(.headline)

                    Picker("Camera", selection: $viewModel.selectedCameraBodyID) {
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

                    Picker("Ambient Preference", selection: $viewModel.ambientPreference) {
                        ForEach(AmbientPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Camera Status")
                        .font(.headline)
                    DetailRow(title: "Permission", value: viewModel.authorizationState.displayName)
                    DetailRow(title: "Session Running", value: viewModel.isSessionRunning ? "Yes" : "No")
                    DetailRow(title: "Depth Support", value: viewModel.depthSupportState.displayName)
                    DetailRow(
                        title: "Ambient Estimate",
                        value: viewModel.latestAmbientEstimate.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "Pending"
                    )
                    DetailRow(
                        title: "Focus Point Support",
                        value: viewModel.subjectSelectionSupport.supportsFocusPointOfInterest ? "Yes" : "No"
                    )
                    DetailRow(
                        title: "Exposure Point Support",
                        value: viewModel.subjectSelectionSupport.supportsExposurePointOfInterest ? "Yes" : "No"
                    )

                    if let tapSelection = viewModel.tapSelection {
                        Text("Selected Point: \(tapSelection.normalizedX, format: .number.precision(.fractionLength(2))), \(tapSelection.normalizedY, format: .number.precision(.fractionLength(2)))")
                            .font(.subheadline)
                    } else {
                        Text("Tap the preview to choose a subject point.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !viewModel.subjectSelectionSupport.supportsAnyPointOfInterest {
                        Text("This device does not support focus or exposure points of interest. The selected point will still feed the recommendation pipeline.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Depth")
                        .font(.headline)

                    Text(viewModel.depthEstimationState.statusLabel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(depthStatusColor.opacity(0.16), in: Capsule())
                        .foregroundStyle(depthStatusColor)

                    if let estimate = viewModel.latestDepthEstimate {
                        DetailRow(title: "Estimated Distance", value: estimate.value.displayValue)
                        DetailRow(title: "Sample Count", value: "\(estimate.sampledPixelCount)")

                        if viewModel.canAcceptEstimatedDistance {
                            Button("Accept Estimated Distance") {
                                viewModel.acceptEstimatedDistance()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("This estimate is relative only. Enter a manual distance to use it in recommendations.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.depthEstimationState == .estimating {
                        Text("Sampling depth around the selected subject point.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if viewModel.depthEstimationState == .unavailable {
                        Text("Depth isn’t available on this device or for the current capture configuration. Enter a manual distance instead.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tap the subject to estimate distance from the latest depth frame.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manual Distance Override")
                            .font(.subheadline.weight(.medium))

                        TextField("Distance in meters", text: $viewModel.manualDistanceText)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onSubmit {
                                viewModel.applyManualDistanceOverride()
                            }

                        Button("Apply Manual Distance") {
                            viewModel.applyManualDistanceOverride()
                        }
                        .buttonStyle(.bordered)

                        if let distanceInputError = viewModel.distanceInputError {
                            Text(distanceInputError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pipeline Readiness")
                        .font(.headline)
                    DetailRow(
                        title: "Video Frames",
                        value: viewModel.framePipelineState.isVideoPipelinePrepared ? "Prepared" : "Pending"
                    )
                    DetailRow(
                        title: "Depth Frames",
                        value: viewModel.framePipelineState.isDepthPipelinePrepared ? "Prepared" : "Pending"
                    )
                    DetailRow(
                        title: "Tap Selection",
                        value: viewModel.framePipelineState.supportsTapSelection ? "Prepared" : "Pending"
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Subject Selection")
                        .font(.headline)

                    Button(viewModel.sceneInput.isSubjectSelectionLocked ? "Unlock Subject Selection" : "Lock Subject Selection") {
                        viewModel.toggleSubjectSelectionLock()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.tapSelection == nil)

                    if viewModel.sceneInput.isSubjectSelectionLocked {
                        Text("Selection is locked. Unlock to pick a new subject point.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tap anywhere on the preview to update focus, exposure, and the recommendation input point.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Scene State")
                        .font(.headline)
                    DetailRow(
                        title: "Ambient Preference",
                        value: viewModel.sceneInput.ambientPreference.displayName
                    )
                    DetailRow(
                        title: "Depth Available",
                        value: viewModel.sceneInput.isDepthAvailable ? "Yes" : "No"
                    )
                    DetailRow(
                        title: "Selection Locked",
                        value: viewModel.sceneInput.isSubjectSelectionLocked ? "Yes" : "No"
                    )
                    DetailRow(
                        title: "Subject Distance",
                        value: "\(viewModel.sceneInput.subjectDistanceMeters.formatted(.number.precision(.fractionLength(1)))) m"
                    )
                    DetailRow(
                        title: "Manual Override",
                        value: viewModel.sceneInput.manualDistanceOverride.map { "\($0.formatted(.number.precision(.fractionLength(2)))) m" } ?? "None"
                    )
                    DetailRow(
                        title: "Accepted Depth Estimate",
                        value: viewModel.sceneInput.depthEstimate.map { "\($0.formatted(.number.precision(.fractionLength(2)))) m" } ?? "None"
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Live Assist")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
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
    }

    @ViewBuilder
    private var previewSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
                .overlay {
                    previewContent
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let recommendation = viewModel.recommendation {
                RecommendationOverlayCard(
                    recommendation: recommendation,
                    distanceSourceLabel: viewModel.distanceSourceLabel,
                    isConfidenceLow: viewModel.isConfidenceLow
                )
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            Text("Rear camera preview")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(16)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch viewModel.authorizationState {
        case .authorized:
            CameraPreviewView(session: viewModel.session) { tapResult in
                viewModel.selectPoint(
                    previewPoint: tapResult.normalizedPreviewPoint,
                    cameraPoint: tapResult.normalizedCameraPoint
                )
            }
            .overlay(alignment: .center) {
                GeometryReader { geometry in
                    if let markerPoint = viewModel.previewMarkerPoint {
                        FocusMarkerView(isLocked: viewModel.sceneInput.isSubjectSelectionLocked)
                            .position(
                                x: markerPoint.x * geometry.size.width,
                                y: markerPoint.y * geometry.size.height
                            )
                    }
                }
            }
        case .notDetermined:
            previewMessage(
                title: "Requesting camera access",
                message: "FlashAssist needs camera permission to run Live Assist."
            )
        case .denied, .restricted:
            previewMessage(
                title: "Camera unavailable",
                message: "Enable camera access in Settings to use Live Assist."
            )
        }
    }

    private func previewMessage(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 32, weight: .medium))
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private var depthStatusColor: Color {
        switch viewModel.depthEstimationState {
        case .available:
            .green
        case .unavailable:
            .orange
        case .estimating:
            .blue
        }
    }

    private func syncPersistedGear() {
        viewModel.updateAvailableGear(
            cameraBodies: cameraBodies.isEmpty ? CameraBody.mockData : cameraBodies,
            lenses: lenses.isEmpty ? Lens.mockData : lenses,
            flashUnits: flashUnits.isEmpty ? FlashUnit.mockData : flashUnits
        )
    }
}

private struct FocusMarkerView: View {
    let isLocked: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isLocked ? Color.yellow : Color.white, lineWidth: 2)
                .frame(width: 44, height: 44)
            Rectangle()
                .fill(isLocked ? Color.yellow : Color.white)
                .frame(width: 18, height: 2)
            Rectangle()
                .fill(isLocked ? Color.yellow : Color.white)
                .frame(width: 2, height: 18)
        }
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }
}

private struct RecommendationOverlayCard: View {
    let recommendation: ExposureRecommendation
    let distanceSourceLabel: String
    let isConfidenceLow: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Live Recommendation")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(distanceSourceLabel)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.14), in: Capsule())
            }

            HStack(spacing: 12) {
                metric("Shutter", recommendation.shutterSpeed)
                metric("Aperture", recommendation.aperture)
                metric("ISO", recommendation.iso)
                metric("Flash", recommendation.flashPowerStep)
            }

            if let primaryReason = recommendation.reasoning.first {
                Text(primaryReason)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let primaryWarning = recommendation.warnings.first {
                Text(primaryWarning)
                    .font(.caption2)
                    .foregroundStyle(Color.yellow)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isConfidenceLow {
                Text("Low confidence")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.18), in: Capsule())
                    .foregroundStyle(Color.yellow)
            }
        }
        .padding(14)
        .frame(width: 270)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}
