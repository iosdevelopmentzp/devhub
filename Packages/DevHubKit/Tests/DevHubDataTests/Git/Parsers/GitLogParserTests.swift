import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GitLogParserTests {
    @Test func parsesTabSeparatedCommits() {
        let log = "aaa111\taaa\tAlice\t1700000000\tp1\tHEAD -> refs/heads/main\tSubject with\ttab\nbbb222\tbbb\tBob\tnot-a-date\tp1 p2\t\tSecond\n"

        let commits = GitLogParser.parse(log, unpushed: ["aaa111"])

        #expect(commits == [
            GitCommit(
                hash: "aaa111",
                shortHash: "aaa",
                author: "Alice",
                date: Date(timeIntervalSince1970: 1_700_000_000),
                subject: "Subject with\ttab",
                isPushed: false,
                refs: [GitCommitRef(kind: .head, name: "HEAD"), GitCommitRef(kind: .localBranch, name: "main")],
                isMerge: false
            ),
            GitCommit(hash: "bbb222", shortHash: "bbb", author: "Bob", date: nil, subject: "Second", isPushed: true, refs: [], isMerge: true),
        ])
    }

    @Test func skipsLinesWithTooFewFields() {
        #expect(GitLogParser.parse("aaa\tbbb\tAlice\n", unpushed: []).isEmpty)
    }

    @Test func hashesReadsOnePerLine() {
        #expect(GitLogParser.hashes("aaa\nbbb\n\naaa\n") == ["aaa", "bbb"])
        #expect(GitLogParser.hashes("").isEmpty)
    }
}
