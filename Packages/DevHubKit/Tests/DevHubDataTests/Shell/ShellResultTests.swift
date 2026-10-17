import Testing
@testable import DevHubData

@Suite struct ShellResultTests {
    @Test func prefersTrimmedStderr() {
        let result = ShellResult(stdout: "out", stderr: "  fatal: bad\n", exitCode: 1)
        #expect(result.failureMessage == "fatal: bad")
    }

    @Test func fallsBackToTrimmedStdout() {
        let result = ShellResult(stdout: "\nsomething failed\n", stderr: " \n", exitCode: 1)
        #expect(result.failureMessage == "something failed")
    }

    @Test func fallsBackToExitCode() {
        let result = ShellResult(stdout: "", stderr: "\n", exitCode: 3)
        #expect(result.failureMessage == "Exited with code 3.")
    }
}
