//
//  GearProfileRepository.swift
//  FlashGuideV2
//

import SwiftData

struct GearProfileRepository {
    func makeCameraBody() -> CameraBody {
        CameraBody()
    }

    func makeLens() -> Lens {
        Lens()
    }

    func makeFlashUnit() -> FlashUnit {
        FlashUnit()
    }

    func save(_ cameraBody: CameraBody, using modelContext: ModelContext) throws {
        modelContext.insert(cameraBody)
        try modelContext.save()
    }

    func save(_ lens: Lens, using modelContext: ModelContext) throws {
        modelContext.insert(lens)
        try modelContext.save()
    }

    func save(_ flashUnit: FlashUnit, using modelContext: ModelContext) throws {
        modelContext.insert(flashUnit)
        try modelContext.save()
    }

    func delete(_ cameraBody: CameraBody, using modelContext: ModelContext, settingsService: SettingsServicing) throws {
        if settingsService.defaultCameraBodyID == cameraBody.id {
            settingsService.defaultCameraBodyID = nil
        }
        modelContext.delete(cameraBody)
        try modelContext.save()
    }

    func delete(_ lens: Lens, using modelContext: ModelContext, settingsService: SettingsServicing) throws {
        if settingsService.defaultLensID == lens.id {
            settingsService.defaultLensID = nil
        }
        modelContext.delete(lens)
        try modelContext.save()
    }

    func delete(_ flashUnit: FlashUnit, using modelContext: ModelContext, settingsService: SettingsServicing) throws {
        if settingsService.defaultFlashUnitID == flashUnit.id {
            settingsService.defaultFlashUnitID = nil
        }
        modelContext.delete(flashUnit)
        try modelContext.save()
    }

}
