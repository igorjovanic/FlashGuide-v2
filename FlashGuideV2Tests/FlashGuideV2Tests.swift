import Testing
@testable import FlashGuideV2

struct FlashGuideV2Tests {
    @Test func recommendationServiceReturnsStarterValues() async throws {
        let service = RecommendationService()
        let output = service.makeRecommendation(for: .empty)

        #expect(output.shutterSpeedDescription.isEmpty == false)
        #expect(output.apertureDescription.isEmpty == false)
        #expect(output.isoDescription.isEmpty == false)
        #expect(output.flashPowerDescription.isEmpty == false)
    }
}
