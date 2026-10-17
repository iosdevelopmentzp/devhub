import Testing
@testable import DevHubDomain

@Suite struct SimulatorStatusPolicyTests {
    @Test func candidatesFollowTheLayerOrderThenTheProject() {
        let layers = [
            ConfigLayerInfo(layer: .global, directory: "/home/.config/devhub", exists: true),
            ConfigLayerInfo(layer: .project, directory: "/repo/.devhub", exists: true),
            ConfigLayerInfo(layer: .user, directory: "/repo/.devhub.local", exists: false)
        ]

        let candidates = SimulatorStatusPolicy.candidates(script: "scripts/status.sh", layers: layers, projectPath: "/repo")

        #expect(candidates == [
            "/repo/.devhub.local/scripts/status.sh",
            "/repo/.devhub/scripts/status.sh",
            "/home/.config/devhub/scripts/status.sh",
            "/repo/scripts/status.sh"
        ])
    }

    @Test func anAbsoluteScriptIsTheOnlyCandidate() {
        #expect(SimulatorStatusPolicy.candidates(script: "/bin/status", layers: [], projectPath: "/repo") == ["/bin/status"])
    }

    @Test func theLastViewDirectiveWins() {
        let lines = ["Reading", #"@devhub {"view": {"keyValues": [["Environment", "staging"], ["User", "qa-12"]]}}"#, #"@devhub {"toast": "done"}"#]

        #expect(SimulatorStatusPolicy.line(from: lines) == "Environment: staging · User: qa-12")
    }

    @Test func withoutAViewTheLastPlainLineWins() {
        #expect(SimulatorStatusPolicy.line(from: ["first", "  second  ", "", #"@devhub {"toast": "x"}"#]) == "second")
        #expect(SimulatorStatusPolicy.line(from: [#"@devhub {"view": {"text": "Signed in"}}"#, "   "]) == "Signed in")
        #expect(SimulatorStatusPolicy.line(from: []) == nil)
    }
}
