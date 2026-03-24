//
//  CameraPreviewPlaceholderView.swift
//  FlashGuideV2
//

import SwiftUI

struct CameraPreviewPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.secondarySystemFill))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 32, weight: .medium))
                    Text("Camera preview placeholder")
                        .font(.headline)
                    Text("Live camera integration belongs in the Camera layer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
    }
}
