//
//  CameraSessionManager.swift
//  FlashGuideV2
//

import AVFoundation
import CoreGraphics
import Foundation

enum CameraAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    var isAuthorized: Bool {
        self == .authorized
    }

    var displayName: String {
        switch self {
        case .notDetermined:
            "Not Determined"
        case .authorized:
            "Authorized"
        case .denied:
            "Denied"
        case .restricted:
            "Restricted"
        }
    }
}

struct CameraFramePipelineState: Equatable {
    var isVideoPipelinePrepared: Bool
    var isDepthPipelinePrepared: Bool
    var supportsTapSelection: Bool

    static let inactive = CameraFramePipelineState(
        isVideoPipelinePrepared: false,
        isDepthPipelinePrepared: false,
        supportsTapSelection: false
    )
}

protocol CameraServicing: AnyObject {
    var session: AVCaptureSession { get }
    var authorizationState: CameraAuthorizationState { get }
    var depthSupportState: DepthSupportState { get }
    var isSessionRunning: Bool { get }
    var framePipelineState: CameraFramePipelineState { get }

    func requestAccessIfNeeded() async -> CameraAuthorizationState
    func startSession()
    func stopSession()
    func selectSubject(at point: CGPoint)
}

final class CameraSessionManager: NSObject, CameraServicing {
    private let sessionQueue = DispatchQueue(label: "flashassist.camera.session", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let depthOutput = AVCaptureDepthDataOutput()

    private(set) var session = AVCaptureSession()
    private(set) var authorizationState: CameraAuthorizationState = .notDetermined
    private(set) var depthSupportState: DepthSupportState = .unknown
    private(set) var isSessionRunning = false
    private(set) var framePipelineState = CameraFramePipelineState.inactive

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var isConfigured = false

    override init() {
        super.init()
        authorizationState = Self.makeAuthorizationState(from: AVCaptureDevice.authorizationStatus(for: .video))
        refreshHardwareCapabilities()
    }

    func requestAccessIfNeeded() async -> CameraAuthorizationState {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if currentStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationState = granted ? .authorized : .denied
        } else {
            authorizationState = Self.makeAuthorizationState(from: currentStatus)
        }

        if authorizationState.isAuthorized {
            refreshHardwareCapabilities()
        }

        return authorizationState
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.authorizationState.isAuthorized {
                return
            }

            if !self.isConfigured {
                self.configureSession()
            }

            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }

    func selectSubject(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDeviceInput?.device else { return }
            guard device.isFocusPointOfInterestSupported || device.isExposurePointOfInterestSupported else { return }

            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                }
                device.unlockForConfiguration()
            } catch {
                return
            }
        }
    }

    private func configureSession() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        do {
            guard let device = bestRearCamera() else {
                DispatchQueue.main.async {
                    self.depthSupportState = .unsupported
                }
                return
            }

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return }
            session.addInput(input)
            videoDeviceInput = input

            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            guard session.canAddOutput(videoOutput) else { return }
            session.addOutput(videoOutput)

            var nextDepthSupportState: DepthSupportState = .unsupported
            var nextPipelineState = CameraFramePipelineState(
                isVideoPipelinePrepared: true,
                isDepthPipelinePrepared: false,
                supportsTapSelection: true
            )

            if !device.activeFormat.supportedDepthDataFormats.isEmpty, session.canAddOutput(depthOutput) {
                session.addOutput(depthOutput)
                depthOutput.isFilteringEnabled = true
                nextDepthSupportState = .supported
                nextPipelineState.isDepthPipelinePrepared = true
            } else if device.activeFormat.supportedDepthDataFormats.isEmpty {
                nextDepthSupportState = .unsupported
            } else {
                nextDepthSupportState = .limited
            }

            isConfigured = true

            DispatchQueue.main.async {
                self.depthSupportState = nextDepthSupportState
                self.framePipelineState = nextPipelineState
            }
        } catch {
            DispatchQueue.main.async {
                self.depthSupportState = .unsupported
                self.framePipelineState = .inactive
            }
        }
    }

    private func refreshHardwareCapabilities() {
        guard authorizationState.isAuthorized else {
            depthSupportState = .unknown
            framePipelineState = .inactive
            return
        }

        guard let device = bestRearCamera() else {
            depthSupportState = .unsupported
            framePipelineState = .inactive
            return
        }

        if !device.activeFormat.supportedDepthDataFormats.isEmpty {
            depthSupportState = .supported
        } else if device.activeFormat.supportedDepthDataFormats.isEmpty {
            depthSupportState = .unsupported
        } else {
            depthSupportState = .limited
        }

        framePipelineState = CameraFramePipelineState(
            isVideoPipelinePrepared: false,
            isDepthPipelinePrepared: depthSupportState == .supported,
            supportsTapSelection: true
        )
    }

    private func bestRearCamera() -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )

        return discoverySession.devices.first
    }

    private static func makeAuthorizationState(from status: AVAuthorizationStatus) -> CameraAuthorizationState {
        switch status {
        case .authorized:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        @unknown default:
            .restricted
        }
    }
}
