//
//  CameraAmbientEstimator.swift
//  FlashGuideV2
//

import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

enum CameraAmbientEstimator {
    private static let minimumLuma = 0.001

    static func estimate(
        from sampleBuffer: CMSampleBuffer,
        around normalizedPoint: CGPoint,
        using device: AVCaptureDevice?
    ) -> AmbientSceneEstimate? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let x = clampedPixelCoordinate(normalizedPoint.x, dimension: width)
        let y = clampedPixelCoordinate(normalizedPoint.y, dimension: height)
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let minDimension = max(min(width, height), 1)
        let subjectRadius = max(18, minDimension / 18)
        let exclusionRadius = max(subjectRadius * 2, minDimension / 9)
        let stride = max(6, minDimension / 44)

        guard let subjectStats = weightedSubjectStats(
            pointer: pointer,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            centerX: x,
            centerY: y,
            radius: subjectRadius
        ) else { return nil }

        let backgroundLuma = sparseMeanLuma(
            pointer: pointer,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            step: stride,
            excluding: (x, y, exclusionRadius)
        ) ?? subjectStats.meanLuma
        let globalLuma = sparseMeanLuma(
            pointer: pointer,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            step: stride,
            excluding: nil
        ) ?? backgroundLuma

        let referenceSceneEV100 = sceneEV100(
            from: device,
            globalLuma: globalLuma
        )

        let normalizedGlobalLuma = max(globalLuma, minimumLuma)
        let subjectEV100 = referenceSceneEV100 + log2(max(subjectStats.meanLuma, minimumLuma) / normalizedGlobalLuma)
        let backgroundEV100 = referenceSceneEV100 + log2(max(backgroundLuma, minimumLuma) / normalizedGlobalLuma)
        let subjectBackgroundDeltaEV = subjectEV100 - backgroundEV100

        return AmbientSceneEstimate(
            subjectEV100: subjectEV100,
            backgroundEV100: backgroundEV100,
            ambientContrastEV: abs(subjectBackgroundDeltaEV),
            subjectBackgroundDeltaEV: subjectBackgroundDeltaEV,
            subjectHighlightRatio: subjectStats.highlightRatio,
            subjectShadowRatio: subjectStats.shadowRatio
        )
    }

    private static func clampedPixelCoordinate(_ normalizedValue: CGFloat, dimension: Int) -> Int {
        guard dimension > 0 else { return 0 }
        let clamped = min(max(normalizedValue, 0), 1)
        return min(max(Int(round(clamped * CGFloat(dimension - 1))), 0), dimension - 1)
    }

    private static func sceneEV100(from device: AVCaptureDevice?, globalLuma: Double) -> Double {
        guard let device,
              device.lensAperture > 0,
              device.exposureDuration.isValid,
              device.exposureDuration.seconds > 0,
              device.iso > 0 else {
            return fallbackEV100(from: globalLuma)
        }

        let apertureSquared = Double(device.lensAperture * device.lensAperture)
        let exposureSeconds = device.exposureDuration.seconds
        let isoScale = Double(device.iso) / 100.0
        let exposureEV100 = log2(apertureSquared / exposureSeconds) - log2(isoScale)
        return exposureEV100
    }

    private static func fallbackEV100(from globalLuma: Double) -> Double {
        1.8 + (log2((max(globalLuma, minimumLuma) * 255.0) + 1.0) * 1.7)
    }

    private static func weightedSubjectStats(
        pointer: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        centerX: Int,
        centerY: Int,
        radius: Int
    ) -> (meanLuma: Double, highlightRatio: Double, shadowRatio: Double)? {
        var weightedLuma = 0.0
        var totalWeight = 0.0
        var highlightWeight = 0.0
        var shadowWeight = 0.0

        for row in max(0, centerY - radius)...min(height - 1, centerY + radius) {
            for column in max(0, centerX - radius)...min(width - 1, centerX + radius) {
                let dx = Double(column - centerX)
                let dy = Double(row - centerY)
                let distanceSquared = (dx * dx) + (dy * dy)
                let normalizedDistance = distanceSquared / max(Double(radius * radius), 1)
                guard normalizedDistance <= 1 else { continue }

                let weight = max(0.15, 1.0 - normalizedDistance)
                let luma = pixelLuma(
                    pointer: pointer,
                    row: row,
                    column: column,
                    bytesPerRow: bytesPerRow
                )
                weightedLuma += luma * weight
                totalWeight += weight

                if luma >= 0.92 {
                    highlightWeight += weight
                }

                if luma <= 0.10 {
                    shadowWeight += weight
                }
            }
        }

        guard totalWeight > 0 else { return nil }
        return (
            meanLuma: weightedLuma / totalWeight,
            highlightRatio: highlightWeight / totalWeight,
            shadowRatio: shadowWeight / totalWeight
        )
    }

    private static func sparseMeanLuma(
        pointer: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        step: Int,
        excluding exclusion: (centerX: Int, centerY: Int, radius: Int)?
    ) -> Double? {
        var totalLuma = 0.0
        var sampleCount = 0.0

        for row in Swift.stride(from: 0, to: height, by: step) {
            for column in Swift.stride(from: 0, to: width, by: step) {
                if let exclusion {
                    let dx = column - exclusion.centerX
                    let dy = row - exclusion.centerY
                    if (dx * dx) + (dy * dy) <= exclusion.radius * exclusion.radius {
                        continue
                    }
                }

                totalLuma += pixelLuma(
                    pointer: pointer,
                    row: row,
                    column: column,
                    bytesPerRow: bytesPerRow
                )
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return nil }
        return totalLuma / sampleCount
    }

    private static func pixelLuma(
        pointer: UnsafePointer<UInt8>,
        row: Int,
        column: Int,
        bytesPerRow: Int
    ) -> Double {
        let pixelOffset = row * bytesPerRow + (column * 4)
        let blue = Double(pointer[pixelOffset]) / 255.0
        let green = Double(pointer[pixelOffset + 1]) / 255.0
        let red = Double(pointer[pixelOffset + 2]) / 255.0
        return (red * 0.2126) + (green * 0.7152) + (blue * 0.0722)
    }
}
