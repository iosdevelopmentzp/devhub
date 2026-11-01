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
