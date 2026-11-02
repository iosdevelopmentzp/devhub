import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct FFprobeInfoParserTests {
    @Test func aScreenRecordingGivesItsSizeLengthAndFrameRate() throws {
        let info = try #require(FFprobeInfoParser.parse(FFmpegFixture.screenRecordingProbe))

        #expect(info.width == 3456)
        #expect(info.height == 2234)
        #expect(info.duration == 5.02)
        #expect(abs((info.frameRate ?? 0) - 17.99) < 0.01)
        #expect(info.codec == "h264")
        #expect(info.hasAudio == false)
        #expect(info.size == 2_067_145)
    }

    @Test func aTurnedVideoSwapsItsSidesAndKnowsItsSound() throws {
        let info = try #require(FFprobeInfoParser.parse(FFmpegFixture.turnedProbeWithSound))

        #expect(info.width == 2234)
        #expect(info.height == 3456)
        #expect(info.duration == 5)
        #expect(info.hasAudio)
    }

    @Test func aFileWithoutAVideoStreamGivesNothing() {
        #expect(FFprobeInfoParser.parse(FFmpegFixture.audioOnlyProbe) == nil)
    }

    @Test func brokenOutputGivesNothing() {
        #expect(FFprobeInfoParser.parse("not json") == nil)
    }
}
