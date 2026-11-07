import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct UpdateCommitParserTests {
    @Test func parsesHashAndSubjectPerLine() {
        let stdout = "a1b2c3d\u{1F}feat(git): stash files\nd4e5f6a\u{1F}fix: a strip of rows \n"

        #expect(UpdateCommitParser.commits(from: stdout) == [
            UpdateCommit(hash: "a1b2c3d", subject: "feat(git): stash files"),
            UpdateCommit(hash: "d4e5f6a", subject: "fix: a strip of rows"),
        ])
    }

    @Test func emptyOutputAndMissingSubjectsAreHandled() {
        #expect(UpdateCommitParser.commits(from: "").isEmpty)
        #expect(UpdateCommitParser.commits(from: "\n\n").isEmpty)
        #expect(UpdateCommitParser.commits(from: "a1b2c3d\n") == [UpdateCommit(hash: "a1b2c3d", subject: "")])
    }
}
