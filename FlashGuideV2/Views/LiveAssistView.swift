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

                    if let tapSelection = viewModel.tapSelection {
                        Text("Selected Point: \(tapSelection.normalizedX, format: .number.precision(.fractionLength(2))), \(tapSelection.normalizedY, format: .number.precision(.fractionLength(2)))")
                            .font(.subheadline)
                    } else {
                        Text("Tap the preview to choose a subject point.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            CameraPreviewView(session: viewModel.session) { point in
                viewModel.selectPoint(x: point.x, y: point.y)
            }
            .overlay(alignment: .center) {
                GeometryReader { geometry in
                    if let tapSelection = viewModel.tapSelection {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                            .frame(width: 36, height: 36)
                            .position(
                                x: tapSelection.normalizedX * geometry.size.width,
                                y: tapSelection.normalizedY * geometry.size.height
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
}
