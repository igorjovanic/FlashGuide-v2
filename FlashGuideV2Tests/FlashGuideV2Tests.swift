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
    @Test func fartherSubjectCanRaiseISOToPreserveAUsefulAperture() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Nikon",
            model: "Z6 III",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 6400
        )
        let lens = Lens(
            brand: "Nikon",
            model: "35mm f/2.8",
            minAperture: 2.8,
            maxAperture: 8.0,
            isVariableAperture: false,
            focalLengthDescription: "35mm"
        )
        let flashUnit = FlashUnit(
            brand: "Godox",
            model: "TT350",
            guideNumber: 36,
            guideNumberISOReference: 100,
            supportedPowerSteps: ["1/1", "1/2", "1/4", "1/8", "1/16", "1/32", "1/64", "1/128"]
        )

        let nearScene = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            lens: lens,
            flashUnit: flashUnit,
            subjectDistanceMeters: 1.5,
            ambientPreference: .balanced,
            ambientMeterValue: 6.0
        )
        let farScene = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            lens: lens,
            flashUnit: flashUnit,
            subjectDistanceMeters: 6.0,
            ambientPreference: .balanced,
            ambientMeterValue: 6.0
        )

        let nearOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: lens,
            flashUnit: flashUnit,
            sceneInput: nearScene
        )
        let farOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: lens,
            flashUnit: flashUnit,
            sceneInput: farScene
        )

        let nearISO = try #require(parsedISO(from: nearOutput.iso))
        let farISO = try #require(parsedISO(from: farOutput.iso))
        #expect(farISO > nearISO)
    }

    @MainActor
    @Test func brighterAmbientPreferenceCanChooseHigherISOThanDarkerBackground() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Canon",
            model: "EOS R6 Mark II",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 6400
        )
        let sceneForDarkerBackground = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 4.0,
            ambientPreference: .darkerBackground,
            ambientMeterValue: 4.0
        )
        let sceneForBrighterAmbient = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 4.0,
            ambientPreference: .brighterAmbient,
            ambientMeterValue: 4.0
        )

        let darkerOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: sceneForDarkerBackground.selectedLens,
            flashUnit: sceneForDarkerBackground.selectedFlashUnit,
            sceneInput: sceneForDarkerBackground
        )
        let brighterOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: sceneForBrighterAmbient.selectedLens,
            flashUnit: sceneForBrighterAmbient.selectedFlashUnit,
            sceneInput: sceneForBrighterAmbient
        )

        let darkerISO = try #require(parsedISO(from: darkerOutput.iso))
        let brighterISO = try #require(parsedISO(from: brighterOutput.iso))
        #expect(brighterISO > darkerISO)
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
