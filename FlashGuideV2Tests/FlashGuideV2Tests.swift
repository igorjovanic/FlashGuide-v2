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
    @Test func darkerSubjectAgainstBrightBackgroundRaisesISOToProtectAmbientBalance() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Sony",
            model: "a7C II",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 6400
        )

        let evenlyLitScene = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            ambientMeterValue: 6.4,
            backgroundAmbientEV: 6.0,
            ambientContrastEV: 0.4
        )
        let backlitScene = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            ambientMeterValue: 5.1,
            backgroundAmbientEV: 7.2,
            ambientContrastEV: 2.1
        )

        let evenlyLitOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: evenlyLitScene.selectedLens,
            flashUnit: evenlyLitScene.selectedFlashUnit,
            sceneInput: evenlyLitScene
        )
        let backlitOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: backlitScene.selectedLens,
            flashUnit: backlitScene.selectedFlashUnit,
            sceneInput: backlitScene
        )

        let evenlyLitISO = try #require(parsedISO(from: evenlyLitOutput.iso))
        let backlitISO = try #require(parsedISO(from: backlitOutput.iso))
        #expect(backlitISO > evenlyLitISO)
        #expect(backlitOutput.warnings.contains(where: { $0.contains("backlighting") }))
    }

    @MainActor
    @Test func highContrastAmbientSceneLowersConfidence() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let normalScene = TestSupport.makeSceneInput(
            subjectDistanceMeters: 2.5,
            ambientPreference: .balanced,
            ambientMeterValue: 6.8,
            backgroundAmbientEV: 6.2,
            ambientContrastEV: 0.6,
            subjectHighlightRatio: 0.04,
            subjectShadowRatio: 0.10
        )
        let contrastyScene = TestSupport.makeSceneInput(
            subjectDistanceMeters: 2.5,
            ambientPreference: .balanced,
            ambientMeterValue: 5.0,
            backgroundAmbientEV: 7.6,
            ambientContrastEV: 2.6,
            subjectHighlightRatio: 0.22,
            subjectShadowRatio: 0.58
        )

        let normalOutput = engine.makeRecommendation(
            cameraBody: normalScene.selectedCameraBody,
            lens: normalScene.selectedLens,
            flashUnit: normalScene.selectedFlashUnit,
            sceneInput: normalScene
        )
        let contrastyOutput = engine.makeRecommendation(
            cameraBody: contrastyScene.selectedCameraBody,
            lens: contrastyScene.selectedLens,
            flashUnit: contrastyScene.selectedFlashUnit,
            sceneInput: contrastyScene
        )

        #expect(contrastyOutput.confidenceScore < normalOutput.confidenceScore)
        #expect(contrastyOutput.warnings.contains(where: { $0.contains("Scene contrast is high") }))
    }

    @MainActor
    @Test func daylightAndNightScenesUseDifferentStrategies() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let cameraBody = CameraBody(
            brand: "Canon",
            model: "EOS R6 Mark II",
            flashSyncSpeed: "1/200",
            minISO: 100,
            maxISO: 6400
        )

        let daylightScene = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            ambientMeterValue: 12.2,
            backgroundAmbientEV: 11.7,
            ambientContrastEV: 0.5,
            subjectHighlightRatio: 0.06,
            subjectShadowRatio: 0.05
        )
        let nightScene = TestSupport.makeSceneInput(
            cameraBody: cameraBody,
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            ambientMeterValue: 3.8,
            backgroundAmbientEV: 3.1,
            ambientContrastEV: 0.7,
            subjectHighlightRatio: 0.01,
            subjectShadowRatio: 0.35
        )

        #expect(daylightScene.ambientEstimate?.sceneKind == .daylight)
        #expect(nightScene.ambientEstimate?.sceneKind == .night)

        let daylightOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: daylightScene.selectedLens,
            flashUnit: daylightScene.selectedFlashUnit,
            sceneInput: daylightScene
        )
        let nightOutput = engine.makeRecommendation(
            cameraBody: cameraBody,
            lens: nightScene.selectedLens,
            flashUnit: nightScene.selectedFlashUnit,
            sceneInput: nightScene
        )

        let daylightISO = try #require(parsedISO(from: daylightOutput.iso))
        let nightISO = try #require(parsedISO(from: nightOutput.iso))
        #expect(nightISO > daylightISO)
        #expect(daylightOutput.reasoning.contains(where: { $0.contains("daylight") }))
        #expect(nightOutput.reasoning.contains(where: { $0.contains("night") }))
    }

    @MainActor
    @Test func manualSceneTypeOverrideAffectsRecommendationWithoutAmbientEstimate() async throws {
        let engine = DefaultExposureRecommendationEngine()
        let daylightManualScene = TestSupport.makeSceneInput(
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            sceneKindOverride: .daylight,
            ambientMeterValue: nil
        )
        let nightManualScene = TestSupport.makeSceneInput(
            subjectDistanceMeters: 3.0,
            ambientPreference: .balanced,
            sceneKindOverride: .night,
            ambientMeterValue: nil
        )

        let daylightOutput = engine.makeRecommendation(
            cameraBody: daylightManualScene.selectedCameraBody,
            lens: daylightManualScene.selectedLens,
            flashUnit: daylightManualScene.selectedFlashUnit,
            sceneInput: daylightManualScene
        )
        let nightOutput = engine.makeRecommendation(
            cameraBody: nightManualScene.selectedCameraBody,
            lens: nightManualScene.selectedLens,
            flashUnit: nightManualScene.selectedFlashUnit,
            sceneInput: nightManualScene
        )

        let daylightISO = try #require(parsedISO(from: daylightOutput.iso))
        let nightISO = try #require(parsedISO(from: nightOutput.iso))
        #expect(nightISO >= daylightISO)
        #expect(daylightOutput.reasoning.contains(where: { $0.contains("Manual scene type daylight") }))
        #expect(nightOutput.reasoning.contains(where: { $0.contains("Manual scene type night") }))
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

        #expect(output.warnings.contains(where: { $0.contains("Ambient scene estimate is missing") }))
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
