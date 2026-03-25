//
//  GearProfilesViewModel.swift
//  FlashGuideV2
//

import Foundation
import Combine
import SwiftData

final class GearProfilesViewModel: ObservableObject {
    private let repository: GearProfileRepository
    private let settingsService: SettingsServicing

    init(repository: GearProfileRepository, settingsService: SettingsServicing) {
        self.repository = repository
        self.settingsService = settingsService
    }

    func seedIfNeeded(using modelContext: ModelContext) {
        repository.seedSampleDataIfNeeded(using: modelContext, settingsService: settingsService)
    }

    var defaultCameraBodyID: UUID? {
        get { settingsService.defaultCameraBodyID }
        set { settingsService.defaultCameraBodyID = newValue }
    }

    var defaultLensID: UUID? {
        get { settingsService.defaultLensID }
        set { settingsService.defaultLensID = newValue }
    }

    var defaultFlashUnitID: UUID? {
        get { settingsService.defaultFlashUnitID }
        set { settingsService.defaultFlashUnitID = newValue }
    }

    func makeCameraBody() -> CameraBody {
        repository.makeCameraBody()
    }

    func makeLens() -> Lens {
        repository.makeLens()
    }

    func makeFlashUnit() -> FlashUnit {
        repository.makeFlashUnit()
    }

    func save(_ cameraBody: CameraBody, using modelContext: ModelContext) throws {
        try repository.save(cameraBody, using: modelContext)
    }

    func save(_ lens: Lens, using modelContext: ModelContext) throws {
        try repository.save(lens, using: modelContext)
    }

    func save(_ flashUnit: FlashUnit, using modelContext: ModelContext) throws {
        try repository.save(flashUnit, using: modelContext)
    }

    func delete(_ cameraBody: CameraBody, using modelContext: ModelContext) throws {
        try repository.delete(cameraBody, using: modelContext, settingsService: settingsService)
    }

    func delete(_ lens: Lens, using modelContext: ModelContext) throws {
        try repository.delete(lens, using: modelContext, settingsService: settingsService)
    }

    func delete(_ flashUnit: FlashUnit, using modelContext: ModelContext) throws {
        try repository.delete(flashUnit, using: modelContext, settingsService: settingsService)
    }
}
