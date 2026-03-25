import Foundation
import Testing
@testable import FlashGuideV2

struct FlashGuideV2Tests {
    @MainActor
    @Test func syncSpeedCapIsRespected() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Sony",
            model: "a7 IV",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 6400
        )
        let sceneInput = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 2.0,
            ambientPreference: .freezeMotion
        )

        let output = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: sceneInput.selectedLens,
            flashUnit: sceneInput.selectedFlashUnit,
            sceneInput: sceneInput
        )

        #expect(output.shutterSpeed == "1/200")
    }

    @MainActor
    @Test func recommendationStaysWithinISOBounds() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Canon",
            model: "EOS R6 Mark II",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 200
        )
        let sceneInput = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 25.0,
            ambientPreference: .balanced
        )

        let output = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: sceneInput.selectedLens,
            flashUnit: sceneInput.selectedFlashUnit,
            sceneInput: sceneInput
        )

        #expect(parsedISO(from: output.iso) == 200)
    }

    @MainActor
    @Test func recommendationStaysWithinApertureBounds() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let lens = Lens(
            brand: "Canon",
            model: "RF 24-105mm F4-7.1",
            minAperture: 4.0,
            maxAperture: 11.0,
            isVariableAperture: true,
            focalLengthDescription: "24-105mm"
        )
        let sceneInput = TestSupport.makeSceneInput(
            lens: lens,
            subjectDistanceMeters: 1.5,
            ambientPreference: .balanced
        )

        let output = engine.makeRecommendation(
            cameraBody: sceneInput.selectedCameraBody,
            lens: lens,
            flashUnit: sceneInput.selectedFlashUnit,
            sceneInput: sceneInput
        )

        let apertureValue = try #require(parsedAperture(from: output.aperture))
        #expect(apertureValue >= lens.minAperture)
        #expect(apertureValue <= lens.maxAperture)
    }

    @MainActor
    @Test func nearSubjectUsesLowerFlashPowerBeforeAnythingElse() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Canon",
            model: "EOS R6 Mark II",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 1600
        )
        let sceneInput = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 0.5,
            ambientPreference: .darkerBackground
        )

        let output = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: sceneInput.selectedLens,
            flashUnit: sceneInput.selectedFlashUnit,
            sceneInput: sceneInput
        )

        #expect(output.shutterSpeed == "1/200")
        #expect(output.flashPowerStep != "1/1")
    }

    @MainActor
    @Test func missingDataProducesWarningsAndLowerConfidence() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let sceneInput = TestSupport.makeSceneInput(
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            ambientMeterValue: nil,
            depthEstimate: nil,
            manualDistanceOverride: nil,
            isDepthAvailable: false
        )

        let output = engine.makeRecommendation(
            cameraBody: sceneInput.selectedCameraBody,
            lens: sceneInput.selectedLens,
            flashUnit: sceneInput.selectedFlashUnit,
            sceneInput: sceneInput
        )

        #expect(output.warnings.contains(where: { $0.contains("Ambient meter value is missing") }))
        #expect(output.warnings.contains(where: { $0.contains("No depth estimate or manual override") }))
        #expect(output.confidenceScore < 0.7)
    }

    private func parsedISO(from value: String) -> Int? {
        Int(value.replacingOccurrences(of: "ISO ", with: ""))
    }

    private func parsedAperture(from value: String) -> Double? {
        Double(value.replacingOccurrences(of: "f/", with: ""))
    }
}
