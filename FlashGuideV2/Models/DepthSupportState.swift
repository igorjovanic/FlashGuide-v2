//
//  DepthSupportState.swift
//  FlashGuideV2
//

import Foundation

enum DepthSupportState: String, Codable, CaseIterable {
    case unknown
    case supported
    case unsupported
    case limited

    var displayName: String {
        switch self {
        case .unknown:
            "Checking"
        case .supported:
            "Supported"
        case .unsupported:
            "Unavailable"
        case .limited:
            "Limited"
        }
    }
}
