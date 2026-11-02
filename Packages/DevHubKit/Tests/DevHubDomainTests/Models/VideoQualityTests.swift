import Testing
@testable import DevHubDomain

@Suite struct VideoQualityTests {
    @Test func eachQualityHasItsLimits() {
        #expect(VideoQuality.allCases.map(\.maximumLongSide) == [nil, 1920, 1280])
        #expect(VideoQuality.allCases.map(\.maximumFrameRate) == [60, 30, 30])
    }

    @Test func theStandardSettingsAreBalancedWithSound() {
        #expect(VideoCompressionSettings.standard == VideoCompressionSettings(quality: .balanced, keepsAudio: true))
    }
}
