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
    @Published var defaultCameraBodyID: UUID? {
        didSet { settingsService.defaultCameraBodyID = defaultCameraBodyID }
    }
    @Published var defaultLensID: UUID? {
        didSet { settingsService.defaultLensID = defaultLensID }
    }
    @Published var defaultFlashUnitID: UUID? {
        didSet { settingsService.defaultFlashUnitID = defaultFlashUnitID }
    }

    init(repository: GearProfileRepository, settingsService: SettingsServicing) {
        self.repository = repository
        self.settingsService = settingsService
        self.defaultCameraBodyID = settingsService.defaultCameraBodyID
        self.defaultLensID = settingsService.defaultLensID
        self.defaultFlashUnitID = settingsService.defaultFlashUnitID
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
