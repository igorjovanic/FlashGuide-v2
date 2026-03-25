//
//  CameraDepthEstimator.swift
//  FlashGuideV2
//

import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

enum CameraDepthEstimationState: Equatable {
    case available
    case unavailable
    case estimating

    var statusLabel: String {
        switch self {
        case .available:
            "Depth available"
        case .unavailable:
            "Depth unavailable"
        case .estimating:
            "Depth estimating"
        }
    }
}

enum CameraDepthEstimateValue: Equatable {
    case meters(Double)
    case relative(Double)

    var acceptedMetersValue: Double? {
        switch self {
        case let .meters(value):
            value
        case .relative:
            nil
        }
    }

    var displayValue: String {
        switch self {
        case let .meters(value):
            "\(value.formatted(.number.precision(.fractionLength(2)))) m"
        case let .relative(value):
            "Relative \(value.formatted(.number.precision(.fractionLength(2))))"
        }
    }
}

struct CameraDepthEstimate: Equatable {
    let value: CameraDepthEstimateValue
    let sampledPixelCount: Int
    let capturedAt: Date
}

struct CameraStateSnapshot: Equatable {
    let authorizationState: CameraAuthorizationState
    let depthSupportState: DepthSupportState
    let depthEstimationState: CameraDepthEstimationState
    let latestDepthEstimate: CameraDepthEstimate?
    let latestAmbientEstimate: Double?
    let isSessionRunning: Bool
    let framePipelineState: CameraFramePipelineState
    let subjectSelectionSupport: CameraSubjectSelectionSupport
}

enum CameraDepthEstimator {
    private static let sampleRadius = 3

    static func estimate(from depthData: AVDepthData, around normalizedPoint: CGPoint) -> CameraDepthEstimate? {
        let convertedDepthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        if let meters = sampleFloat32Depth(from: convertedDepthData.depthDataMap, around: normalizedPoint) {
            return CameraDepthEstimate(
                value: .meters(meters.value),
                sampledPixelCount: meters.sampleCount,
                capturedAt: Date()
            )
        }

        if let relative = sampleRelativeDepth(from: depthData.depthDataMap, around: normalizedPoint, pixelFormat: depthData.depthDataType) {
            return CameraDepthEstimate(
                value: .relative(relative.value),
                sampledPixelCount: relative.sampleCount,
                capturedAt: Date()
            )
        }

        return nil
    }

    private static func sampleFloat32Depth(
        from pixelBuffer: CVPixelBuffer,
        around normalizedPoint: CGPoint
    ) -> (value: Double, sampleCount: Int)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let rowStride = CVPixelBufferGetBytesPerRow(pixelBuffer) / MemoryLayout<Float32>.stride
        let x = clampedPixelCoordinate(normalizedPoint.x, dimension: width)
        let y = clampedPixelCoordinate(normalizedPoint.y, dimension: height)

        let pointer = baseAddress.assumingMemoryBound(to: Float32.self)
        var samples: [Double] = []
        samples.reserveCapacity((sampleRadius * 2 + 1) * (sampleRadius * 2 + 1))

        for row in max(0, y - sampleRadius)...min(height - 1, y + sampleRadius) {
            for column in max(0, x - sampleRadius)...min(width - 1, x + sampleRadius) {
                let value = pointer[row * rowStride + column]
                if value.isFinite, value > 0 {
                    samples.append(Double(value))
                }
            }
        }

        guard !samples.isEmpty else { return nil }
        samples.sort()
        return (samples[samples.count / 2], samples.count)
    }

    private static func sampleRelativeDepth(
        from pixelBuffer: CVPixelBuffer,
        around normalizedPoint: CGPoint,
        pixelFormat: OSType
    ) -> (value: Double, sampleCount: Int)? {
        switch pixelFormat {
        case kCVPixelFormatType_DisparityFloat32:
            return sampleDisparityFloat32(from: pixelBuffer, around: normalizedPoint)
        case kCVPixelFormatType_DisparityFloat16:
            return sampleDisparityFloat16(from: pixelBuffer, around: normalizedPoint)
        default:
            return nil
        }
    }

    private static func sampleDisparityFloat32(
        from pixelBuffer: CVPixelBuffer,
        around normalizedPoint: CGPoint
    ) -> (value: Double, sampleCount: Int)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let rowStride = CVPixelBufferGetBytesPerRow(pixelBuffer) / MemoryLayout<Float32>.stride
        let x = clampedPixelCoordinate(normalizedPoint.x, dimension: width)
        let y = clampedPixelCoordinate(normalizedPoint.y, dimension: height)
        let pointer = baseAddress.assumingMemoryBound(to: Float32.self)

        var samples: [Double] = []
        for row in max(0, y - sampleRadius)...min(height - 1, y + sampleRadius) {
            for column in max(0, x - sampleRadius)...min(width - 1, x + sampleRadius) {
                let value = pointer[row * rowStride + column]
                if value.isFinite, value > 0 {
                    samples.append(Double(value))
                }
            }
        }

        guard !samples.isEmpty else { return nil }
        samples.sort()
        return (samples[samples.count / 2], samples.count)
    }

    private static func sampleDisparityFloat16(
        from pixelBuffer: CVPixelBuffer,
        around normalizedPoint: CGPoint
    ) -> (value: Double, sampleCount: Int)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let rowStride = CVPixelBufferGetBytesPerRow(pixelBuffer) / MemoryLayout<UInt16>.stride
        let x = clampedPixelCoordinate(normalizedPoint.x, dimension: width)
        let y = clampedPixelCoordinate(normalizedPoint.y, dimension: height)
        let pointer = baseAddress.assumingMemoryBound(to: UInt16.self)

        var samples: [Double] = []
        for row in max(0, y - sampleRadius)...min(height - 1, y + sampleRadius) {
            for column in max(0, x - sampleRadius)...min(width - 1, x + sampleRadius) {
                let rawValue = pointer[row * rowStride + column]
                let value = Float16(bitPattern: rawValue)
                if value.isFinite, value > 0 {
                    samples.append(Double(value))
                }
            }
        }

        guard !samples.isEmpty else { return nil }
        samples.sort()
        return (samples[samples.count / 2], samples.count)
    }

    private static func clampedPixelCoordinate(_ normalizedValue: CGFloat, dimension: Int) -> Int {
        guard dimension > 0 else { return 0 }
        let clamped = min(max(normalizedValue, 0), 1)
        return min(max(Int(round(clamped * CGFloat(dimension - 1))), 0), dimension - 1)
    }
}
