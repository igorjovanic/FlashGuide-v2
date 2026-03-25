//
//  LiveAssistViewModel.swift
//  FlashGuideV2
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class LiveAssistViewModel: ObservableObject {
    @Published private(set) var authorizationState: CameraAuthorizationState
    @Published private(set) var depthSupportState: DepthSupportState
    @Published private(set) var isSessionRunning: Bool
    @Published private(set) var framePipelineState: CameraFramePipelineState
    @Published var tapSelection: UserTapSelection?
    @Published var sceneInput = SceneInput.empty

    var session: AVCaptureSession {
        cameraService.session
    }

    private let cameraService: CameraServicing

    init(cameraService: CameraServicing) {
        self.cameraService = cameraService
        self.authorizationState = cameraService.authorizationState
        self.depthSupportState = cameraService.depthSupportState
        self.isSessionRunning = cameraService.isSessionRunning
        self.framePipelineState = cameraService.framePipelineState
        sceneInput.isDepthAvailable = cameraService.depthSupportState == .supported
    }

    func onAppear() {
        Task {
            await requestCameraAccessIfNeeded()
            startSessionIfAuthorized()
        }
    }

    func onDisappear() {
        cameraService.stopSession()
        syncStateFromCamera()
    }

    func requestCameraAccessIfNeeded() async {
        authorizationState = await cameraService.requestAccessIfNeeded()
        syncStateFromCamera()
    }

    func refreshDepthSupport() {
        syncStateFromCamera()
    }

    func startSessionIfAuthorized() {
        guard authorizationState.isAuthorized else { return }
        cameraService.startSession()
        syncStateFromCamera()
    }

    func selectPoint(x: Double, y: Double) {
        let selection = UserTapSelection(
            normalizedX: max(0, min(1, x)),
            normalizedY: max(0, min(1, y))
        )
        tapSelection = selection
        sceneInput.selectedTapPoint = selection
        sceneInput.isSubjectSelectionLocked = true
        cameraService.selectSubject(at: selection.point)
    }

    private func syncStateFromCamera() {
        authorizationState = cameraService.authorizationState
        depthSupportState = cameraService.depthSupportState
        isSessionRunning = cameraService.isSessionRunning
        framePipelineState = cameraService.framePipelineState
        sceneInput.isDepthAvailable = depthSupportState == .supported
    }
}
