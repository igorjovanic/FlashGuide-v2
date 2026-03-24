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

        modelContext.insert(CameraBody())
        modelContext.insert(Lens())
        modelContext.insert(FlashUnit())

        try? modelContext.save()
    }
}
