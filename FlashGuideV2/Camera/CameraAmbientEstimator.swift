//
//  CameraAmbientEstimator.swift
//  FlashGuideV2
//

import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

enum CameraAmbientEstimator {
    private static let sampleRadius = 6

    // The recommendation engine expects a simple ambient meter input, not a
    // photometrically precise lux or EV reading. We derive a stable EV-like
    // proxy from the tapped preview region using luma only so the camera layer
    // remains lightweight and independent from flash math.
    static func estimate(from sampleBuffer: CMSampleBuffer, around normalizedPoint: CGPoint) -> Double? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let planeIndex = 0
        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex) else { return nil }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex)
        let x = clampedPixelCoordinate(normalizedPoint.x, dimension: width)
        let y = clampedPixelCoordinate(normalizedPoint.y, dimension: height)

        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var totalLuma = 0.0
        var sampleCount = 0.0

        for row in max(0, y - sampleRadius)...min(height - 1, y + sampleRadius) {
            for column in max(0, x - sampleRadius)...min(width - 1, x + sampleRadius) {
                let value = pointer[row * bytesPerRow + column]
                totalLuma += Double(value) / 255.0
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return nil }
        let averageLuma = totalLuma / sampleCount
        return 4.0 + (averageLuma * 8.0)
    }

    private static func clampedPixelCoordinate(_ normalizedValue: CGFloat, dimension: Int) -> Int {
        guard dimension > 0 else { return 0 }
        let clamped = min(max(normalizedValue, 0), 1)
        return min(max(Int(round(clamped * CGFloat(dimension - 1))), 0), dimension - 1)
    }
}
