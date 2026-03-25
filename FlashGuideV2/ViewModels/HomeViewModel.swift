//
//  HomeViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine

enum HomeDestination: String, CaseIterable, Hashable, Identifiable {
    case manualCalculator = "Manual Calculator"
    case liveAssist = "Live Assist"
    case gearProfiles = "Gear Profiles"
    case history = "Recommendation History"
    case help = "Quick Help"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .manualCalculator:
            "dial.medium"
        case .liveAssist:
            "viewfinder"
        case .gearProfiles:
            "camera.aperture"
        case .history:
            "clock.arrow.circlepath"
        case .help:
            "questionmark.circle"
        case .settings:
            "gearshape"
        }
    }
}

final class HomeViewModel: ObservableObject {
    let destinations = HomeDestination.allCases
}
