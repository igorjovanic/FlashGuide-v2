//
//  CameraSessionManager.swift
//  FlashGuideV2
//

import AVFoundation
import CoreMedia
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

struct CameraSubjectSelectionSupport: Equatable {
    var supportsFocusPointOfInterest: Bool
    var supportsExposurePointOfInterest: Bool

    var supportsAnyPointOfInterest: Bool {
        supportsFocusPointOfInterest || supportsExposurePointOfInterest
    }

    static let unavailable = CameraSubjectSelectionSupport(
        supportsFocusPointOfInterest: false,
        supportsExposurePointOfInterest: false
    )
}

protocol CameraServicing: AnyObject {
    var session: AVCaptureSession { get }
    var authorizationState: CameraAuthorizationState { get }
    var depthSupportState: DepthSupportState { get }
    var depthEstimationState: CameraDepthEstimationState { get }
    var latestDepthEstimate: CameraDepthEstimate? { get }
    var latestAmbientEstimate: AmbientSceneEstimate? { get }
    var isSessionRunning: Bool { get }
    var framePipelineState: CameraFramePipelineState { get }
    var subjectSelectionSupport: CameraSubjectSelectionSupport { get }
    var onStateChange: ((CameraStateSnapshot) -> Void)? { get set }

    func requestAccessIfNeeded() async -> CameraAuthorizationState
    func startSession()
    func stopSession()
    func selectSubject(at point: CGPoint)
}

final class CameraSessionManager: NSObject, CameraServicing, AVCaptureDepthDataOutputDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let sessionQueue = DispatchQueue(label: "flashassist.camera.session", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let depthOutput = AVCaptureDepthDataOutput()

    private(set) var session = AVCaptureSession()
    private(set) var authorizationState: CameraAuthorizationState = .notDetermined
    private(set) var depthSupportState: DepthSupportState = .unknown
    private(set) var depthEstimationState: CameraDepthEstimationState = .unavailable
    private(set) var latestDepthEstimate: CameraDepthEstimate?
    private(set) var latestAmbientEstimate: AmbientSceneEstimate?
    private(set) var isSessionRunning = false
    private(set) var framePipelineState = CameraFramePipelineState.inactive
    private(set) var subjectSelectionSupport = CameraSubjectSelectionSupport.unavailable
    var onStateChange: ((CameraStateSnapshot) -> Void)?

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var isConfigured = false
    private var latestDepthData: AVDepthData?
    private var pendingDepthSamplePoint: CGPoint?
    private var activeAmbientSamplePoint: CGPoint?
    private var lastAmbientPublishTimestamp = Date.distantPast

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

        publishState()

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
            self.updateStateOnMain {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            self.updateStateOnMain {
                self.isSessionRunning = false
            }
        }
    }

    func selectSubject(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.videoDeviceInput?.device else { return }
            self.activeAmbientSamplePoint = point

            do {
                if device.isFocusPointOfInterestSupported || device.isExposurePointOfInterestSupported {
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
                }
            } catch {
                return
            }

            guard self.depthSupportState == .supported else {
                self.updateStateOnMain {
                    self.depthEstimationState = .unavailable
                    self.latestDepthEstimate = nil
                }
                return
            }

            self.pendingDepthSamplePoint = point
            self.updateStateOnMain {
                self.depthEstimationState = .estimating
            }
            self.resolvePendingDepthEstimateIfPossible()
        }
    }

    private func configureSession() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        do {
            guard let device = bestRearCamera() else {
                updateStateOnMain {
                    self.depthSupportState = .unsupported
                    self.depthEstimationState = .unavailable
                    self.latestDepthEstimate = nil
                    self.subjectSelectionSupport = .unavailable
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
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

            var nextDepthSupportState: DepthSupportState = .unsupported
            let nextSubjectSelectionSupport = CameraSubjectSelectionSupport(
                supportsFocusPointOfInterest: device.isFocusPointOfInterestSupported,
                supportsExposurePointOfInterest: device.isExposurePointOfInterestSupported
            )
            var nextPipelineState = CameraFramePipelineState(
                isVideoPipelinePrepared: true,
                isDepthPipelinePrepared: false,
                supportsTapSelection: true
            )

            if !device.activeFormat.supportedDepthDataFormats.isEmpty, session.canAddOutput(depthOutput) {
                session.addOutput(depthOutput)
                depthOutput.isFilteringEnabled = true
                depthOutput.alwaysDiscardsLateDepthData = true
                depthOutput.setDelegate(self, callbackQueue: sessionQueue)
                nextDepthSupportState = .supported
                nextPipelineState.isDepthPipelinePrepared = true
            } else if device.activeFormat.supportedDepthDataFormats.isEmpty {
                nextDepthSupportState = .unsupported
            } else {
                nextDepthSupportState = .limited
            }

            isConfigured = true

            updateStateOnMain {
                self.depthSupportState = nextDepthSupportState
                self.depthEstimationState = nextDepthSupportState == .supported ? .available : .unavailable
                self.framePipelineState = nextPipelineState
                self.subjectSelectionSupport = nextSubjectSelectionSupport
            }
        } catch {
            updateStateOnMain {
                self.depthSupportState = .unsupported
                self.depthEstimationState = .unavailable
                self.latestDepthEstimate = nil
                self.framePipelineState = .inactive
                self.subjectSelectionSupport = .unavailable
            }
        }
    }

    private func refreshHardwareCapabilities() {
        guard authorizationState.isAuthorized else {
            depthSupportState = .unknown
            depthEstimationState = .unavailable
            latestDepthEstimate = nil
            latestAmbientEstimate = nil
            framePipelineState = .inactive
            subjectSelectionSupport = .unavailable
            return
        }

        guard let device = bestRearCamera() else {
            depthSupportState = .unsupported
            depthEstimationState = .unavailable
            latestDepthEstimate = nil
            latestAmbientEstimate = nil
            framePipelineState = .inactive
            subjectSelectionSupport = .unavailable
            return
        }

        subjectSelectionSupport = CameraSubjectSelectionSupport(
            supportsFocusPointOfInterest: device.isFocusPointOfInterestSupported,
            supportsExposurePointOfInterest: device.isExposurePointOfInterestSupported
        )

        if !device.activeFormat.supportedDepthDataFormats.isEmpty {
            depthSupportState = .supported
            depthEstimationState = .available
        } else if device.activeFormat.supportedDepthDataFormats.isEmpty {
            depthSupportState = .unsupported
            depthEstimationState = .unavailable
        } else {
            depthSupportState = .limited
            depthEstimationState = .unavailable
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

    func depthDataOutput(
        _ output: AVCaptureDepthDataOutput,
        didOutput depthData: AVDepthData,
        timestamp: CMTime,
        connection: AVCaptureConnection
    ) {
        latestDepthData = depthData

        if pendingDepthSamplePoint != nil {
            resolvePendingDepthEstimateIfPossible()
        } else if depthSupportState == .supported, depthEstimationState != .available {
            updateStateOnMain {
                self.depthEstimationState = .available
            }
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard output === videoOutput, let point = activeAmbientSamplePoint else { return }
        guard let estimate = CameraAmbientEstimator.estimate(
            from: sampleBuffer,
            around: point,
            using: videoDeviceInput?.device
        ) else { return }

        let now = Date()
        let shouldPublish = latestAmbientEstimate == nil
            || abs((latestAmbientEstimate?.subjectEV100 ?? estimate.subjectEV100) - estimate.subjectEV100) > 0.18
            || abs((latestAmbientEstimate?.ambientContrastEV ?? estimate.ambientContrastEV) - estimate.ambientContrastEV) > 0.22
            || now.timeIntervalSince(lastAmbientPublishTimestamp) > 0.35

        guard shouldPublish else { return }

        lastAmbientPublishTimestamp = now
        updateStateOnMain {
            self.latestAmbientEstimate = estimate
        }
    }

    private func resolvePendingDepthEstimateIfPossible() {
        guard let point = pendingDepthSamplePoint, let depthData = latestDepthData else { return }
        guard let estimate = CameraDepthEstimator.estimate(from: depthData, around: point) else { return }

        pendingDepthSamplePoint = nil
        updateStateOnMain {
            self.latestDepthEstimate = estimate
            self.depthEstimationState = .available
        }
    }

    private func updateStateOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
            self.publishState()
        }
    }

    private func publishState() {
        onStateChange?(CameraStateSnapshot(
            authorizationState: authorizationState,
            depthSupportState: depthSupportState,
            depthEstimationState: depthEstimationState,
            latestDepthEstimate: latestDepthEstimate,
            latestAmbientEstimate: latestAmbientEstimate,
            isSessionRunning: isSessionRunning,
            framePipelineState: framePipelineState,
            subjectSelectionSupport: subjectSelectionSupport
        ))
    }
}
