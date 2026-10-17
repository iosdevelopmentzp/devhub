import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct ShellScriptRunnerTests {
    private let directory: TemporaryDirectory

    init() throws {
        directory = try TemporaryDirectory()
    }

    @Test func aScriptWithoutTheExecutableBitRunsThroughZsh() throws {
        let path = try directory.write("echo hi", to: "build.sh").path

        let invocation = ShellScriptRunner.invocation(request(path))

        #expect(invocation.executable == "/bin/zsh")
        #expect(invocation.arguments == [path, "--fast"])
    }

    @Test func anExecutableScriptRunsItself() throws {
        let path = try directory.write("echo hi", to: "run.sh").path
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)

        let invocation = ShellScriptRunner.invocation(request(path))

        #expect(invocation.executable == path)
        #expect(invocation.arguments == ["--fast"])
    }

    @Test func aCommandNameOrAMissingFileStaysAsItIs() {
        #expect(ShellScriptRunner.invocation(request("make")).executable == "make")
        #expect(ShellScriptRunner.invocation(request(directory.path("missing.sh"))).executable == directory.path("missing.sh"))
    }

    private func request(_ executable: String) -> ScriptRunRequest {
        ScriptRunRequest(executable: executable, arguments: ["--fast"], cwd: nil, environment: [:])
    }
}
