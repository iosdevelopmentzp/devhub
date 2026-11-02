import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct FFmpegOutputParserTests {
    @Test func aProgressBlockGivesTheTimeAndTheSpeed() {
        let parser = FFmpegOutputParser()

        let updates = FFmpegFixture.progressBlock.components(separatedBy: "\n").compactMap(parser.read)

        #expect(updates == [VideoCompressionProgress(seconds: 5, speed: 21)])
        #expect(parser.messages.isEmpty)
    }

    @Test func theFirstBlockWithoutValuesStartsAtZero() {
        let parser = FFmpegOutputParser()

        let updates = FFmpegFixture.startBlock.components(separatedBy: "\n").compactMap(parser.read)

        #expect(updates == [VideoCompressionProgress(seconds: 0, speed: nil)])
    }

    @Test func otherLinesAreMessagesWithoutTheComponentPrefix() {
        let parser = FFmpegOutputParser()

        FFmpegFixture.missingInput.components(separatedBy: "\n").forEach { _ = parser.read($0) }

        #expect(parser.messages == [
            "Error opening input: No such file or directory",
            "Error opening input file nothere.mov.",
            "Error opening input files: No such file or directory",
        ])
        #expect(parser.failure(exitCode: 254) == parser.messages.joined(separator: "\n"))
    }

    @Test func aFailureWithoutMessagesNamesTheExitCode() {
        #expect(FFmpegOutputParser().failure(exitCode: 1) == "ffmpeg stopped with exit code 1.")
    }
}
