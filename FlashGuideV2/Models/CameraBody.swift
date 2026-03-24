//
//  CameraBody.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

@Model
final class CameraBody {
    var name: String
    var syncSpeedDenominator: Int
    var isoMin: Int
    var isoMax: Int
    var createdAt: Date

    init(
        name: String = "Primary Camera",
        syncSpeedDenominator: Int = 200,
        isoMin: Int = 100,
        isoMax: Int = 6400,
        createdAt: Date = .now
    ) {
        self.name = name
        self.syncSpeedDenominator = syncSpeedDenominator
        self.isoMin = isoMin
        self.isoMax = isoMax
        self.createdAt = createdAt
    }
}
