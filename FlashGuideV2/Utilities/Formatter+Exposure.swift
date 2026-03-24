//
//  Formatter+Exposure.swift
//  FlashGuideV2
//

import Foundation

enum ExposureFormatter {
    static func shutterSpeed(denominator: Int) -> String {
        "1/\(denominator)"
    }
}
