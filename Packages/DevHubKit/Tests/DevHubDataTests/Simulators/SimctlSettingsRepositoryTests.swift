import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct SimctlSettingsRepositoryTests {
    private func commands(_ setting: SimulatorSetting) -> [[String]] {
        SimctlSettingsRepository.commands(for: setting, udid: "U1")
    }

    @Test func uiSettingsUseSimctlUI() {
        #expect(commands(.appearance(.dark)) == [["ui", "U1", "appearance", "dark"]])
        #expect(commands(.textSize(.accessibilityLarge)) == [["ui", "U1", "content_size", "accessibility-large"]])
    }

    @Test func theCleanStatusBarShowsNineFortyOneAndAFullBattery() throws {
        let command = try #require(commands(.cleanStatusBar).first)

        #expect(command.prefix(3) == ["status_bar", "U1", "override"])
        #expect(command.contains("9:41"))
        #expect(command.contains("--batteryLevel"))
        #expect(commands(.resetStatusBar) == [["status_bar", "U1", "clear"]])
    }

    @Test func locationLanguageAndPrivacy() {
        #expect(commands(.location(latitude: 50.45, longitude: 30.52)) == [["location", "U1", "set", "50.45,30.52"]])
        #expect(commands(.clearLocation) == [["location", "U1", "clear"]])
        #expect(commands(.language(code: "de", locale: "de_DE")) == [
            ["spawn", "U1", "defaults", "write", "-g", "AppleLanguages", "-array", "de"],
            ["spawn", "U1", "defaults", "write", "-g", "AppleLocale", "-string", "de_DE"],
        ])
        #expect(commands(.privacy(.grant, service: .photos, bundleID: "com.example.app")) == [["privacy", "U1", "grant", "photos", "com.example.app"]])
        #expect(commands(.privacy(.reset, service: .all, bundleID: "")) == [["privacy", "U1", "reset", "all"]])
    }

    @Test func aRecordingIsAnH264VideoThatReplacesAnOldFile() {
        #expect(SimctlSettingsRepository.recordArguments(udid: "U1", path: "/tmp/a.mov") == ["simctl", "io", "U1", "recordVideo", "--codec=h264", "--mask=black", "--force", "/tmp/a.mov"])
        #expect(SimctlSettingsRepository.startedLine == "Recording started")
    }
}
