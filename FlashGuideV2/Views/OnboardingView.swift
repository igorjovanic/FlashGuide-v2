//
//  OnboardingView.swift
//  FlashGuideV2
//

import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Starting Point Only") {
                    Text("FlashAssist gives starting points for exposure, not guaranteed perfect results.")
                }
                Section("Data Quality Matters") {
                    Text("Best results depend on accurate flash guide numbers, realistic distance input, and matching gear data.")
                }
                Section("Depth Support") {
                    Text("Automatic distance estimation depends on device capability and capture support. Unsupported devices can still use manual distance entry.")
                }
            }
            .navigationTitle("Welcome to FlashAssist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Continue") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
