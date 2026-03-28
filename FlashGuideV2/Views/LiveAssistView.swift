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
        Group {
            if viewModel.availableCameraBodies.isEmpty || viewModel.availableLenses.isEmpty || viewModel.availableFlashUnits.isEmpty {
                ContentUnavailableView(
                    "Live Assist Needs Gear",
                    systemImage: "viewfinder.circle",
                    description: Text("Add your camera body, lens, and flash profiles before using Live Assist.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        previewSection

                        if let recommendation = viewModel.recommendation {
                            RecommendationOverlayCard(
                                recommendation: recommendation,
                                distanceSourceLabel: viewModel.distanceSourceLabel,
                                isConfidenceLow: viewModel.isConfidenceLow
                            )
                        }

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
                    }
                    .padding()
                }
            }
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
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.black)
            .overlay {
                previewContent
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .accessibilityLabel("Live camera preview")
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

    private func syncPersistedGear() {
        viewModel.updateAvailableGear(
            cameraBodies: cameraBodies,
            lenses: lenses,
            flashUnits: flashUnits
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
        .accessibilityHidden(true)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live recommendation")
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
