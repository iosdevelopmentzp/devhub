import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIToolStateParserTests {
    @Test func theVersionComesFromTheJSONAnswer() {
        let result = ShellResult(stdout: String(decoding: CircleCIFixture.version, as: UTF8.self), stderr: "", exitCode: 0)

        #expect(CircleCIToolStateParser.version(from: result) == "1.13.0")
    }

    @Test func anOldToolPrintsPlainTextWithItsVersion() {
        let result = ShellResult(stdout: "", stderr: "Error: unknown flag: --json\n" + CircleCIFixture.oldVersionText, exitCode: 1)

        #expect(CircleCIToolStateParser.version(from: result) == "0.1.31425")
    }

    @Test func noVersionNumberIsNil() {
        #expect(CircleCIToolStateParser.version(from: ShellResult(stdout: "custom build", stderr: "", exitCode: 0)) == nil)
    }

    @Test func theLoginStateIsTheTokenSetFlag() {
        #expect(CircleCIToolStateParser.isLoggedIn(ShellResult(stdout: String(decoding: CircleCIFixture.settingsLoggedIn, as: UTF8.self), stderr: "", exitCode: 0)))
        #expect(CircleCIToolStateParser.isLoggedIn(ShellResult(stdout: String(decoding: CircleCIFixture.settingsLoggedOut, as: UTF8.self), stderr: "", exitCode: 0)) == false)
        #expect(CircleCIToolStateParser.isLoggedIn(ShellResult(stdout: String(decoding: CircleCIFixture.settingsLoggedIn, as: UTF8.self), stderr: "", exitCode: 1)) == false)
        #expect(CircleCIToolStateParser.isLoggedIn(ShellResult(stdout: "{}", stderr: "", exitCode: 0)) == false)
    }
}
