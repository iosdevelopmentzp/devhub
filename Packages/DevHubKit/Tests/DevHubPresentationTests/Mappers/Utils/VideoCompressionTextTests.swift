import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct VideoCompressionTextTests {
    @Test func everyQualityHasATitleAndADescription() {
        #expect(VideoQuality.allCases.map(VideoCompressionText.title) == ["High", "Balanced", "Small"])
        #expect(VideoQuality.allCases.allSatisfy { VideoCompressionText.description(for: $0).isEmpty == false })
    }

    @Test func theFactsNameTheSizeTheFrameRateAndAMissingSound() {
        let facts = VideoCompressionText.facts(of: VideoFileInfo(duration: 5, width: 1920, height: 1080, frameRate: 29.97, codec: "h264", hasAudio: false, size: 1_000_000))

        #expect(facts.hasPrefix("1920 × 1080 · 30 fps · "))
        #expect(facts.hasSuffix(" · no sound"))
    }
}
