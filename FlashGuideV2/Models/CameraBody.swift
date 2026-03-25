//
//  CameraBody.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

@Model
final class CameraBody: Codable, Hashable {
    var id: UUID
    var brand: String
    var model: String
    var flashSyncSpeed: String
    var minISO: Int
    var maxISO: Int
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        brand: String = "Canon",
        model: String = "EOS R6 Mark II",
        flashSyncSpeed: String = "1/200",
        minISO: Int = 100,
        maxISO: Int = 102400,
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.flashSyncSpeed = flashSyncSpeed
        self.minISO = minISO
        self.maxISO = maxISO
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case model
        case flashSyncSpeed
        case minISO
        case maxISO
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            brand: try container.decode(String.self, forKey: .brand),
            model: try container.decode(String.self, forKey: .model),
            flashSyncSpeed: try container.decode(String.self, forKey: .flashSyncSpeed),
            minISO: try container.decode(Int.self, forKey: .minISO),
            maxISO: try container.decode(Int.self, forKey: .maxISO)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(brand, forKey: .brand)
        try container.encode(model, forKey: .model)
        try container.encode(flashSyncSpeed, forKey: .flashSyncSpeed)
        try container.encode(minISO, forKey: .minISO)
        try container.encode(maxISO, forKey: .maxISO)
    }

    static func == (lhs: CameraBody, rhs: CameraBody) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static var preview: CameraBody {
        CameraBody(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            brand: "Canon",
            model: "EOS R6 Mark II",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 102400
        )
    }

    static var mockData: [CameraBody] {
        [
            CameraBody(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                brand: "Canon",
                model: "EOS R6 Mark II",
                flashSyncSpeed: "1/200",
                minISO: 100,
                maxISO: 102400
            ),
            CameraBody(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                brand: "Sony",
                model: "a7 IV",
                flashSyncSpeed: "1/250",
                minISO: 100,
                maxISO: 51200
            )
        ]
    }
}
