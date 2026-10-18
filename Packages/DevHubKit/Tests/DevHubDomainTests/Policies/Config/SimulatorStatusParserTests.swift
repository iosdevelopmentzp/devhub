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

    @Test func theLastStateDirectiveIsTheReport() {
        let lines = [
            #"@devhub {"state": {"identity": "old"}}"#,
            #"@devhub {"state": {"identity": "qa-1", "user": "sam"}}"#,
            "Env: qa",
        ]

        #expect(SimulatorStatusParser.state(lines) == AppStateReport(identity: "qa-1", profile: nil, host: nil, user: "sam", version: nil))
        #expect(SimulatorStatusParser.state(["Env: qa"]) == nil)
    }
}
