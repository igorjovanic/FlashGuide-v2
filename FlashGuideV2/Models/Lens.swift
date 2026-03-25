//
//  Lens.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

@Model
final class Lens: Codable, Hashable {
    var id: UUID
    var brand: String
    var model: String
    var minAperture: Double
    var maxAperture: Double
    var isVariableAperture: Bool
    var focalLengthDescription: String?
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        brand: String = "Sigma",
        model: String = "24-70mm F2.8 DG DN Art",
        minAperture: Double = 2.8,
        maxAperture: Double = 22.0,
        isVariableAperture: Bool = false,
        focalLengthDescription: String? = "24-70mm",
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.minAperture = minAperture
        self.maxAperture = maxAperture
        self.isVariableAperture = isVariableAperture
        self.focalLengthDescription = focalLengthDescription
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case model
        case minAperture
        case maxAperture
        case isVariableAperture
        case focalLengthDescription
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            brand: try container.decode(String.self, forKey: .brand),
            model: try container.decode(String.self, forKey: .model),
            minAperture: try container.decode(Double.self, forKey: .minAperture),
            maxAperture: try container.decode(Double.self, forKey: .maxAperture),
            isVariableAperture: try container.decode(Bool.self, forKey: .isVariableAperture),
            focalLengthDescription: try container.decodeIfPresent(String.self, forKey: .focalLengthDescription)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(brand, forKey: .brand)
        try container.encode(model, forKey: .model)
        try container.encode(minAperture, forKey: .minAperture)
        try container.encode(maxAperture, forKey: .maxAperture)
        try container.encode(isVariableAperture, forKey: .isVariableAperture)
        try container.encodeIfPresent(focalLengthDescription, forKey: .focalLengthDescription)
    }

    static func == (lhs: Lens, rhs: Lens) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static var preview: Lens {
        Lens(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            brand: "Sigma",
            model: "24-70mm F2.8 DG DN Art",
            minAperture: 2.8,
            maxAperture: 22.0,
            isVariableAperture: false,
            focalLengthDescription: "24-70mm"
        )
    }

    static var mockData: [Lens] {
        [
            Lens(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
                brand: "Sigma",
                model: "24-70mm F2.8 DG DN Art",
                minAperture: 2.8,
                maxAperture: 22.0,
                isVariableAperture: false,
                focalLengthDescription: "24-70mm"
            ),
            Lens(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
                brand: "Canon",
                model: "RF 24-105mm F4-7.1 IS STM",
                minAperture: 4.0,
                maxAperture: 32.0,
                isVariableAperture: true,
                focalLengthDescription: "24-105mm"
            )
        ]
    }
}
