//
//  LiveAssistView.swift
//  FlashGuideV2
//

import SwiftUI

struct LiveAssistView: View {
    @StateObject private var viewModel: LiveAssistViewModel

    init(viewModel: LiveAssistViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                previewSection

                VStack(alignment: .leading, spacing: 12) {
                    Text("Camera Status")
                        .font(.headline)
                    DetailRow(title: "Permission", value: viewModel.authorizationState.displayName)
                    DetailRow(title: "Session Running", value: viewModel.isSessionRunning ? "Yes" : "No")
                    DetailRow(title: "Depth Support", value: viewModel.depthSupportState.displayName)
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
