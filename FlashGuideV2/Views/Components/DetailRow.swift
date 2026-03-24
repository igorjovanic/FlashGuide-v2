//
//  DetailRow.swift
//  FlashGuideV2
//

import SwiftUI

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
