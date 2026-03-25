//
//  GearProfileRepository.swift
//  FlashGuideV2
//

import SwiftData

struct GearProfileRepository {
    func seedSampleDataIfNeeded(using modelContext: ModelContext) {
        var descriptor = FetchDescriptor<CameraBody>()
        descriptor.fetchLimit = 1

        guard (try? modelContext.fetch(descriptor).isEmpty) != false else {
            return
        }

        CameraBody.mockData.forEach(modelContext.insert)
        Lens.mockData.forEach(modelContext.insert)
        FlashUnit.mockData.forEach(modelContext.insert)

        try? modelContext.save()
    }
}
