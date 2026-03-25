//
//  FlashUnit.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

@Model
final class FlashUnit: Codable, Hashable {
    var id: UUID
    var brand: String
    var model: String
    var guideNumber: Double
    var guideNumberISOReference: Int
    var supportedPowerSteps: [String]
    var notes: String
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        brand: String = "Godox",
        model: String = "V1",
        guideNumber: Double = 60.0,
        guideNumberISOReference: Int = 100,
        supportedPowerSteps: [String] = ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128"],
        notes: String = "Round-head flash with TTL and HSS support.",
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.guideNumber = guideNumber
        self.guideNumberISOReference = guideNumberISOReference
        self.supportedPowerSteps = supportedPowerSteps
        self.notes = notes
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case model
        case guideNumber
        case guideNumberISOReference
        case supportedPowerSteps
        case notes
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            brand: try container.decode(String.self, forKey: .brand),
            model: try container.decode(String.self, forKey: .model),
            guideNumber: try container.decode(Double.self, forKey: .guideNumber),
            guideNumberISOReference: try container.decode(Int.self, forKey: .guideNumberISOReference),
            supportedPowerSteps: try container.decode([String].self, forKey: .supportedPowerSteps),
            notes: try container.decode(String.self, forKey: .notes)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(brand, forKey: .brand)
        try container.encode(model, forKey: .model)
        try container.encode(guideNumber, forKey: .guideNumber)
        try container.encode(guideNumberISOReference, forKey: .guideNumberISOReference)
        try container.encode(supportedPowerSteps, forKey: .supportedPowerSteps)
        try container.encode(notes, forKey: .notes)
    }

    static func == (lhs: FlashUnit, rhs: FlashUnit) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static var preview: FlashUnit {
        FlashUnit(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
            brand: "Godox",
            model: "V1",
            guideNumber: 60.0,
            guideNumberISOReference: 100,
            supportedPowerSteps: ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128"],
            notes: "Round-head flash with TTL and HSS support."
        )
    }

    static var mockData: [FlashUnit] {
        [
            FlashUnit(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
                brand: "Godox",
                model: "V1",
                guideNumber: 60.0,
                guideNumberISOReference: 100,
                supportedPowerSteps: ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128"],
                notes: "Round-head flash with TTL and HSS support."
            ),
            FlashUnit(
                id: UUID(uuidString: "66666666-6666-6666-6666-666666666666") ?? UUID(),
                brand: "Profoto",
                model: "A10",
                guideNumber: 76.0,
                guideNumberISOReference: 100,
                supportedPowerSteps: ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128", "1/256"],
                notes: "High-output on-camera flash with AirX connectivity."
            )
        ]
    }
}
