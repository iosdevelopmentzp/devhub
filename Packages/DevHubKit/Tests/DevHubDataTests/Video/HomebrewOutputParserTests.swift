import Foundation
import Testing
@testable import DevHubData

@Suite struct HomebrewOutputParserTests {
    @Test func headingLinesAreTheSteps() {
        let steps = FFmpegFixture.homebrewInstall.components(separatedBy: "\n").compactMap(HomebrewOutputParser.step)

        #expect(steps == [
            "Downloading Homebrew API data",
            "Fetching downloads for: ffmpeg",
            "Installing ffmpeg dependency: dav1d (1.5.4)",
            "Pouring dav1d--1.5.4.arm64_tahoe.bottle.tar.gz",
            "Pouring ffmpeg--9.0.2_1.arm64_tahoe.bottle.tar.gz",
        ])
    }

    @Test func theFailureIsTheErrorLine() {
        let lines = FFmpegFixture.homebrewFailure.components(separatedBy: "\n")

        #expect(HomebrewOutputParser.failure(from: lines, exitCode: 1) == "Cannot write to /opt/homebrew/Cellar")
    }

    @Test func withoutAnErrorLineTheFailureIsTheLastLine() {
        #expect(HomebrewOutputParser.failure(from: ["==> Pouring x264", "Killed", ""], exitCode: 137) == "Killed")
        #expect(HomebrewOutputParser.failure(from: [], exitCode: 1) == "brew stopped with exit code 1.")
    }
}
