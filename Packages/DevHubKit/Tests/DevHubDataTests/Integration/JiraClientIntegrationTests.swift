import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct JiraClientIntegrationTests {
    private let recorder = SpyCommandRecorder()
    private let shell: ShellRunner
    private let folder: TemporaryDirectory
    private let fakeJira: String

    init() throws {
        shell = ShellRunner(recorder: recorder)
        folder = try TemporaryDirectory()
        let script = """
        #!/bin/sh
        if [ "$JIRA_API_TOKEN" != "token-from-zshrc" ]; then
          echo "The tool needs a Jira API token to function." >&2
          exit 1
        fi
        echo "alex@example.com auth=$JIRA_AUTH_TYPE"
        """
        let file = try folder.write(script, to: "bin/jira")
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
        fakeJira = file.path
    }

    @Test func aFailedLoginRetriesWithTheVariablesOfTheZshrcAndNeverRecordsTheToken() async throws {
        _ = try folder.write("echo welcome\necho noise >&2\nexport JIRA_API_TOKEN=token-from-zshrc\nexport JIRA_AUTH_TYPE=bearer\n", to: "zdot/.zshrc")
        let environment = JiraShellEnvironment(variables: LoginShellVariables(shell: shell, environment: ["ZDOTDIR": folder.path("zdot")], timeout: .seconds(10)))
        let client = JiraClient(shell: shell, executable: fakeJira, environment: environment)

        let first = try await client.run(JiraClient.meArguments())
        let second = try await client.run(JiraClient.meArguments())

        #expect(String(decoding: first, as: UTF8.self) == "alex@example.com auth=bearer\n")
        #expect(String(decoding: second, as: UTF8.self) == "alex@example.com auth=bearer\n")
        #expect(await environment.isNeeded)
        #expect(startedCommands.filter { $0.hasPrefix(fakeJira) }.count == 3)
        #expect(recordedText.contains("token-from-zshrc") == false)
        #expect(recordedKinds.contains(.secret))
    }

    @Test func withoutVariablesTheLoginFailureStays() async throws {
        _ = try folder.write("echo nothing here\n", to: "zdot/.zshrc")
        let environment = JiraShellEnvironment(variables: LoginShellVariables(shell: shell, environment: ["ZDOTDIR": folder.path("zdot")], timeout: .seconds(10)))
        let client = JiraClient(shell: shell, executable: fakeJira, environment: environment)

        await #expect(throws: TrackerError.notLoggedIn) { try await client.run(JiraClient.meArguments()) }
        #expect(await environment.isNeeded == false)
    }

    @Test func aSlowZshrcIsStoppedByTheTimeoutAndNotReadAgain() async throws {
        _ = try folder.write("sleep 30\nexport JIRA_API_TOKEN=late\n", to: "zdot/.zshrc")
        let variables = LoginShellVariables(shell: shell, environment: ["ZDOTDIR": folder.path("zdot")], timeout: .milliseconds(500))
        let start = ContinuousClock.now

        let first = await variables.read(JiraShellEnvironment.names)
        let second = await variables.read(JiraShellEnvironment.names)

        #expect(first.isEmpty)
        #expect(second.isEmpty)
        #expect(ContinuousClock.now - start < .seconds(10))
        #expect(startedCommands.filter { $0.hasPrefix("zsh") }.count == 1)
    }

    private var startedCommands: [String] {
        recorder.events.compactMap { event in
            guard case .started(let command, _, _, _) = event.payload else { return nil }
            return command
        }
    }

    private var recordedKinds: [CommandKind] {
        recorder.events.compactMap { event in
            guard case .started(_, _, let kind, _) = event.payload else { return nil }
            return kind
        }
    }

    private var recordedText: String {
        recorder.events.map { event in
            switch event.payload {
            case .started(let command, _, _, _): command
            case .output(let lines): lines.joined(separator: "\n")
            case .finished(_, let error): error ?? ""
            }
        }
        .joined(separator: "\n")
    }
}
