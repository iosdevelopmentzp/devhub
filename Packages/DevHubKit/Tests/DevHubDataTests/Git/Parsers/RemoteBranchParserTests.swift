import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct RemoteBranchParserTests {
    @Test func skipsHeadAndBareRemote() {
        let refs = [
            "origin/HEAD\t2000\tGitLab\tHead",
            "origin\t2000\tGitLab\tRemote",
            "origin/dev\t1700000000\tSam\tMerge branch\twith tab",
            "origin/feature\tnot-a-date\tBob\tWork",
            "origin/broken\t1",
        ].joined(separator: "\n")

        #expect(RemoteBranchParser.parse(refs) == [
            RemoteBranch(name: "origin/dev", author: "Sam", subject: "Merge branch\twith tab", commitDate: Date(timeIntervalSince1970: 1_700_000_000)),
            RemoteBranch(name: "origin/feature", author: "Bob", subject: "Work", commitDate: nil),
        ])
    }
}
