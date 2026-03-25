import Testing
@testable import FlashGuideV2

struct FlashGuideV2Tests {
    @MainActor
    @Test func recommendationServiceReturnsStarterValues() async throws {
        let service = RecommendationService()
        let output = service.makeRecommendation(for: .empty)

        #expect(output.shutterSpeed.isEmpty == false)
        #expect(output.aperture.isEmpty == false)
        #expect(output.iso.isEmpty == false)
        #expect(output.flashPowerStep.isEmpty == false)
        #expect(output.reasoning.isEmpty == false)
    }
}
