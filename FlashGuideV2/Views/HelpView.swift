//
//  HelpView.swift
//  FlashGuideV2
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            helpSection(
                title: "Sync Speed",
                body: "The fastest shutter speed your camera can use with normal flash without clipping the frame."
            )
            helpSection(
                title: "Guide Number",
                body: "A rough measure of flash power. Higher guide numbers usually mean more flash reach."
            )
            helpSection(
                title: "Aperture",
                body: "Controls how much light the lens lets in and how much depth of field you get."
            )
            helpSection(
                title: "ISO",
                body: "Controls sensor sensitivity. Higher ISO helps exposure but also increases noise."
            )
            helpSection(
                title: "Flash Power",
                body: "The fraction of full output your flash fires. Lower steps recycle faster and reduce overpowering close subjects."
            )
        }
        .navigationTitle("Quick Help")
    }

    private func helpSection(title: String, body: String) -> some View {
        Section(title) {
            Text(body)
                .foregroundStyle(.secondary)
        }
    }
}
