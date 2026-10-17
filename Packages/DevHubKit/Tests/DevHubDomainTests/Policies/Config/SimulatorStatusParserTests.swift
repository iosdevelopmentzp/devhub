import Testing
@testable import DevHubDomain

@Suite struct SimulatorStatusParserTests {
    @Test func theLastViewWins() {
        let lines = ["first", #"@devhub {"view": {"keyValues": [["Env", "qa"], ["User", "sam"]]}}"#, ""]

        #expect(SimulatorStatusParser.parse(lines) == "Env: qa · User: sam")
    }

    @Test func elseTheLastPlainLine() {
        #expect(SimulatorStatusParser.parse(["one", "two ", #"@devhub {"toast": "x"}"#]) == "two")
        #expect(SimulatorStatusParser.parse([]) == nil)
    }
}
