import Foundation
import Testing
@testable import DevHubDomain

@Suite struct VideoCompressionErrorTests {
    @Test func aMissingEngineNamesTheInstallCommand() {
        #expect(VideoCompressionError.engineMissing.localizedDescription.contains("brew install ffmpeg"))
    }

    @Test func aFileThatIsNotAVideoNamesTheFile() {
        #expect(VideoCompressionError.notAVideo("notes.txt").localizedDescription.hasPrefix("notes.txt is not a video."))
    }

    @Test func aReadFailureNamesTheFileAndTheReason() {
        #expect(VideoCompressionError.unreadable("clip.mov", reason: "Invalid data found when processing input").localizedDescription == "Cannot read clip.mov: Invalid data found when processing input")
    }

    @Test func anInstallFailureNamesTheCommand() {
        #expect(VideoCompressionError.installFailed("No space left on device").localizedDescription == "brew install ffmpeg failed: No space left on device")
    }
}
