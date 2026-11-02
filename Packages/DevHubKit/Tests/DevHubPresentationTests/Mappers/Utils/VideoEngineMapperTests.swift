import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct VideoEngineMapperTests {
    @Test func aReadyEngineIsOneGreenLineWithThePath() {
        let model = VideoEngineMapper.model(for: .ready(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg"), install: .idle, isChecking: false)

        #expect(model.title == "ffmpeg 9.0.2")
        #expect(model.detail == "/opt/homebrew/bin/ffmpeg")
        #expect(model.tint == .green)
        #expect(model.isCompact)
        #expect(model.action == nil)
    }

    @Test func aMissingEngineWithHomebrewOffersTheInstall() {
        let model = VideoEngineMapper.model(for: .missing(homebrewPath: "/opt/homebrew/bin/brew"), install: .idle, isChecking: false)

        #expect(model.title == "ffmpeg is not installed")
        #expect(model.action == .install("Install ffmpeg"))
        #expect(model.command == "brew install ffmpeg")
        #expect(model.tint == .orange)
        #expect(model.isCompact == false)
    }

    @Test func withoutHomebrewTheCardLeadsToHomebrew() {
        let model = VideoEngineMapper.model(for: .missing(homebrewPath: nil), install: .idle, isChecking: false)

        #expect(model.title == "ffmpeg and Homebrew are not installed")
        #expect(model.action == .getHomebrew)
        #expect(VideoCompressionText.homebrewPage?.host() == "github.com")
    }

    @Test func anEngineWithoutX264AsksForAReinstall() {
        let model = VideoEngineMapper.model(for: .incomplete(version: "6.1", path: "/usr/local/bin/ffmpeg", missing: "libx264"), install: .idle, isChecking: false)

        #expect(model.title == "ffmpeg 6.1 has no libx264")
        #expect(model.command == "brew reinstall ffmpeg")
        #expect(model.action == .checkAgain)
    }

    @Test func aRunningInstallShowsTheStep() {
        let model = VideoEngineMapper.model(for: .missing(homebrewPath: "/opt/homebrew/bin/brew"), install: .running(step: "Pouring x264--r3222.bottle.tar.gz"), isChecking: false)

        #expect(model.title == "Installing ffmpeg with Homebrew…")
        #expect(model.detail == "Pouring x264--r3222.bottle.tar.gz")
        #expect(model.isWorking)
        #expect(model.action == nil)
    }

    @Test func aFailedInstallOffersTryAgain() {
        let model = VideoEngineMapper.model(for: .missing(homebrewPath: "/opt/homebrew/bin/brew"), install: .failed("No space left on device"), isChecking: false)

        #expect(model.title == "Could not install ffmpeg")
        #expect(model.detail == "No space left on device")
        #expect(model.action == .install("Try Again"))
        #expect(model.tint == .red)
    }

    @Test func beforeTheFirstCheckTheCardIsLooking() {
        let model = VideoEngineMapper.model(for: nil, install: .idle, isChecking: true)

        #expect(model.title == "Looking for ffmpeg…")
        #expect(model.isWorking)
    }
}
