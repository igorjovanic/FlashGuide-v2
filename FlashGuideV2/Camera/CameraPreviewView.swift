//
//  CameraPreviewView.swift
//  FlashGuideV2
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreviewTapResult {
    let normalizedPreviewPoint: CGPoint
    let normalizedCameraPoint: CGPoint
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let onTap: (CameraPreviewTapResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
        context.coordinator.onTap = onTap
    }

    final class Coordinator: NSObject {
        var onTap: (CameraPreviewTapResult) -> Void

        init(onTap: @escaping (CameraPreviewTapResult) -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? PreviewContainerView else { return }
            let location = recognizer.location(in: view)
            let tapResult = CameraPreviewCoordinateConverter.convertTap(
                at: location,
                in: view.bounds,
                using: view.previewLayer
            )
            onTap(tapResult)
        }
    }
}

enum CameraPreviewCoordinateConverter {
    // AVCapture uses normalized device coordinates that are not the same as raw
    // SwiftUI view coordinates once aspect-fill cropping is applied. Keep this
    // conversion isolated so preview UI can use preview-space points while camera
    // controls and recommendation input use device-space normalized points.
    static func convertTap(
        at location: CGPoint,
        in bounds: CGRect,
        using previewLayer: AVCaptureVideoPreviewLayer
    ) -> CameraPreviewTapResult {
        let normalizedPreviewPoint = CGPoint(
            x: clamp(location.x / max(bounds.width, 1)),
            y: clamp(location.y / max(bounds.height, 1))
        )
        let normalizedCameraPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)

        return CameraPreviewTapResult(
            normalizedPreviewPoint: normalizedPreviewPoint,
            normalizedCameraPoint: CGPoint(
                x: clamp(normalizedCameraPoint.x),
                y: clamp(normalizedCameraPoint.y)
            )
        )
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}

final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}
