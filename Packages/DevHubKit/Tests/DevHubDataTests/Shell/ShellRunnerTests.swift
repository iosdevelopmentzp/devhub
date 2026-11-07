import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct ShellRunnerTests {
    private let base = ["PATH": "/usr/bin:/bin", "HOME": "/Users/alex"]
    private let developerDir = "/Applications/Xcode-beta.app/Contents/Developer"

    @Test func xcodeToolsGetTheDeveloperFolder() {
        for tool in ["xcodebuild", "xcrun", "xed"] {
            let environment = ShellRunner.environment(for: tool, base: base, extra: [:], developerDir: developerDir)

            #expect(environment["DEVELOPER_DIR"] == developerDir)
        }
    }

    @Test func otherToolsAndNoChoiceKeepTheSystemXcode() {
        #expect(ShellRunner.environment(for: "git", base: base, extra: [:], developerDir: developerDir)["DEVELOPER_DIR"] == nil)
        #expect(ShellRunner.environment(for: "xcodebuild", base: base, extra: [:], developerDir: nil)["DEVELOPER_DIR"] == nil)
    }

    @Test func everyChildProcessOptsOutOfTelemetry() {
        let environment = ShellRunner.environment(for: "gh", base: base.merging(["GH_TELEMETRY": "true"]) { $1 }, extra: [:], developerDir: nil)

        #expect(environment["GH_TELEMETRY"] == "false")
        #expect(environment["GH_NO_UPDATE_NOTIFIER"] == "1")
        #expect(environment["DO_NOT_TRACK"] == "1")
        #expect(environment["HOMEBREW_NO_ANALYTICS"] == "1")
        #expect(environment["CIRCLE_NO_TELEMETRY"] == "1")
        #expect(environment["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] == "1")
        #expect(ShellRunner.environment(for: "gh", base: base, extra: ["DO_NOT_TRACK": "0"], developerDir: nil)["DO_NOT_TRACK"] == "0")
    }

    @Test func theExtraEnvironmentWins() {
        let environment = ShellRunner.environment(for: "xcrun", base: base, extra: ["DEVELOPER_DIR": "/Other"], developerDir: developerDir)

        #expect(environment["DEVELOPER_DIR"] == "/Other")
        #expect(environment["HOME"] == "/Users/alex")
        #expect(environment["PATH"] == "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin")
    }

    @Test func theToolEnvironmentSetsTheFolderOfTheRunner() async {
        let runner = ShellRunner(recorder: SpyCommandRecorder())

        await ShellToolEnvironmentRepository(state: runner.developerDir).setDeveloperDir(developerDir)

        #expect(runner.developerDir.value == developerDir)
        #expect(runner.developerDir.xcodeAppName() == "/Applications/Xcode-beta.app")
        await ShellToolEnvironmentRepository(state: runner.developerDir).setDeveloperDir(nil)
        #expect(runner.developerDir.xcodeAppName() == "Xcode")
    }
}
