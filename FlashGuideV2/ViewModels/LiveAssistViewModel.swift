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
    @Published private(set) var subjectSelectionSupport: CameraSubjectSelectionSupport
    @Published var tapSelection: UserTapSelection?
    @Published var previewMarkerPoint: CGPoint?
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
        self.subjectSelectionSupport = cameraService.subjectSelectionSupport
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

    func selectPoint(previewPoint: CGPoint, cameraPoint: CGPoint) {
        guard !sceneInput.isSubjectSelectionLocked else { return }

        let selection = UserTapSelection(
            normalizedX: max(0, min(1, Double(cameraPoint.x))),
            normalizedY: max(0, min(1, Double(cameraPoint.y)))
        )
        tapSelection = selection
        previewMarkerPoint = CGPoint(
            x: max(0, min(1, previewPoint.x)),
            y: max(0, min(1, previewPoint.y))
        )
        sceneInput.selectedTapPoint = selection
        cameraService.selectSubject(at: selection.point)
    }

    func toggleSubjectSelectionLock() {
        guard tapSelection != nil else { return }
        sceneInput.isSubjectSelectionLocked.toggle()
    }

    func clearSelectionLock() {
        sceneInput.isSubjectSelectionLocked = false
    }

    private func syncStateFromCamera() {
        authorizationState = cameraService.authorizationState
        depthSupportState = cameraService.depthSupportState
        isSessionRunning = cameraService.isSessionRunning
        framePipelineState = cameraService.framePipelineState
        subjectSelectionSupport = cameraService.subjectSelectionSupport
        sceneInput.isDepthAvailable = depthSupportState == .supported
    }
}
