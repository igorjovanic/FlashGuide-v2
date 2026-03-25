//
//  DistanceUnit.swift
//  FlashGuideV2
//

import Foundation

enum DistanceUnit: String, CaseIterable, Codable, Hashable, Identifiable {
    case meters
    case feet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meters:
            "Meters"
        case .feet:
            "Feet"
        }
    }

    func format(distanceInMeters value: Double) -> String {
        switch self {
        case .meters:
            return "\(value.formatted(.number.precision(.fractionLength(1)))) m"
        case .feet:
            let feetValue = value * 3.28084
            return "\(feetValue.formatted(.number.precision(.fractionLength(1)))) ft"
        }
    }
}
