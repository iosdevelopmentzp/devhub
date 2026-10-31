import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct ShellScriptRunnerIntegrationTests {
    private let recorder = SpyCommandRecorder()

    @Test func streamsLinesThenTheExitCode() async throws {
        let runner = ShellScriptRunner(shell: ShellRunner(recorder: recorder))
        var events: [ScriptEvent] = []

        for try await event in runner.run(ScriptRunRequest(executable: "/bin/sh", arguments: ["-c", #"echo one; echo "@devhub {\"toast\": \"$DEVHUB_NAME\"}"; exit 3"#], cwd: nil, environment: ["DEVHUB_NAME": "sam"])) {
            events.append(event)
        }

        #expect(events == [.output("one"), .output(#"@devhub {"toast": "sam"}"#), .exited(3)])
        #expect(recorder.events.isEmpty == false)
    }

    @Test func aTimeoutStopsTheScript() async throws {
        let runner = ShellScriptRunner(shell: ShellRunner(recorder: recorder))

        await #expect(throws: ScriptError.timedOut(.milliseconds(200))) {
            for try await _ in runner.run(ScriptRunRequest(executable: "/bin/sleep", arguments: ["30"], cwd: nil, environment: [:], timeout: .milliseconds(200))) {}
        }
    }
}
