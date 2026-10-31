import Testing
@testable import DevHubDomain

@Suite struct FailureDigestPolicyTests {
    @Test func picksTheLinesThatExplainARejectedPush() {
        let lines = [
            "To github.com:example/app.git",
            " ! [rejected]        feature/ABC-123 -> feature/ABC-123 (fetch first)",
            "error: failed to push some refs to 'github.com:example/app.git'",
            "hint: Updates were rejected because the remote contains work that you do not",
            "hint: have locally.",
        ]

        #expect(FailureDigestPolicy.digest(lines) == [
            "! [rejected]        feature/ABC-123 -> feature/ABC-123 (fetch first)",
            "error: failed to push some refs to 'github.com:example/app.git'",
            "hint: Updates were rejected because the remote contains work that you do not",
            "hint: have locally.",
        ])
    }

    @Test func fallsBackToTheLastLinesWhenNoLineTellsTheReason() {
        let lines = (1...9).map { "step \($0)" }

        #expect(FailureDigestPolicy.digest(lines) == ["step 4", "step 5", "step 6", "step 7", "step 8", "step 9"])
    }

    @Test func keepsTheLastTellingLinesUpToTheLimit() {
        let lines = (1...12).map { "error: problem \($0)" }

        let digest = FailureDigestPolicy.digest(lines)

        #expect(digest.count == FailureDigestPolicy.lineLimit)
        #expect(digest.first == "error: problem 5")
        #expect(digest.last == "error: problem 12")
    }

    @Test func dropsEmptyLinesColourCodesAndRepeats() {
        let lines = ["", "\u{1B}[31mfatal: not a git repository\u{1B}[0m", "  ", "fatal: not a git repository"]

        #expect(FailureDigestPolicy.digest(lines) == ["fatal: not a git repository"])
    }

    @Test func emptyOutputGivesNoLines() {
        #expect(FailureDigestPolicy.digest([]) == [])
        #expect(FailureDigestPolicy.digest(["", " "]) == [])
    }

    @Test func matchesWordsInAnyCase() {
        let lines = ["Building…", "Permission Denied (publickey).", "Done"]

        #expect(FailureDigestPolicy.digest(lines) == ["Permission Denied (publickey)."])
    }
}
