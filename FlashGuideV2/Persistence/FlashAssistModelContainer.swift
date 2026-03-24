//
//  FlashAssistModelContainer.swift
//  FlashGuideV2
//

import SwiftData

enum FlashAssistModelContainer {
    static func makeSharedContainer() -> ModelContainer {
        makeContainer(isStoredInMemoryOnly: false)
    }

    static func previewContainer() -> ModelContainer {
        let container = makeContainer(isStoredInMemoryOnly: true)
        let repository = GearProfileRepository()
        repository.seedSampleDataIfNeeded(using: container.mainContext)
        return container
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = Schema([
            CameraBody.self,
            Lens.self,
            FlashUnit.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}
