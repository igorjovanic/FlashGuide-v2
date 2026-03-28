//
//  FlashAssistModelContainer.swift
//  FlashGuideV2
//

import Foundation
import SwiftData

enum FlashAssistModelContainer {
    private static let storeName = "FlashAssist"

    static func makeSharedContainer() -> ModelContainer {
        makeContainer(isStoredInMemoryOnly: false)
    }

    static func previewContainer() -> ModelContainer {
        let container = makeContainer(isStoredInMemoryOnly: true)
        CameraBody.mockData.forEach(container.mainContext.insert)
        Lens.mockData.forEach(container.mainContext.insert)
        FlashUnit.mockData.forEach(container.mainContext.insert)
        try? container.mainContext.save()
        return container
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = Schema([
            CameraBody.self,
            Lens.self,
            FlashUnit.self,
        ])
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly ? nil : storeName,
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            guard !isStoredInMemoryOnly else {
                fatalError("Failed to create in-memory SwiftData container: \(error)")
            }

            resetPersistentStore()

            do {
                let resetConfiguration = ModelConfiguration(storeName, schema: schema)
                return try ModelContainer(for: schema, configurations: [resetConfiguration])
            } catch {
                fatalError("Failed to create SwiftData container after resetting store: \(error)")
            }
        }
    }

    private static func resetPersistentStore() {
        let fileManager = FileManager.default
        let searchRoots = [
            URL.applicationSupportDirectory,
            URL.documentsDirectory,
            URL.cachesDirectory
        ]

        for root in searchRoots {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                let lastPathComponent = fileURL.lastPathComponent

                guard lastPathComponent.contains(storeName) else {
                    continue
                }

                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}
