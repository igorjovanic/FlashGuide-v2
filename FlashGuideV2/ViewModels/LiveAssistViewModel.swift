//
//  LiveAssistViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine

final class LiveAssistViewModel: ObservableObject {
    @Published var depthSupportState: DepthSupportState
    @Published var tapSelection: UserTapSelection?
    @Published var sceneInput = SceneInput.empty

    private let cameraService: CameraServicing

    init(cameraService: CameraServicing) {
        self.cameraService = cameraService
        self.depthSupportState = cameraService.currentDepthSupportState()
    }

    func refreshDepthSupport() {
        depthSupportState = cameraService.currentDepthSupportState()
    }

    func selectPoint(x: Double, y: Double) {
        tapSelection = UserTapSelection(normalizedX: x, normalizedY: y)
        sceneInput.selectedPoint = tapSelection?.point
    }
}
