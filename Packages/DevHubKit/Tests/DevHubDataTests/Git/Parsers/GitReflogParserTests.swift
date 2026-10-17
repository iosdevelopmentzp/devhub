import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GitReflogParserTests {
    @Test func readsTheSelectorTimeActionAndMessage() {
        let reflog = """
        aaa111\taaa\tHEAD@{1700000000}\tcommit (amend): Fix the: login
        bbb222\tbbb\tHEAD@{1699990000}\tcheckout: moving from dev to main
        ccc333\tccc\tHEAD@{bad}\treset
        """

        #expect(GitReflogParser.parse(reflog) == [
            GitReflogEntry(index: 0, hash: "aaa111", shortHash: "aaa", date: Date(timeIntervalSince1970: 1_700_000_000), action: "commit (amend)", message: "Fix the: login"),
            GitReflogEntry(index: 1, hash: "bbb222", shortHash: "bbb", date: Date(timeIntervalSince1970: 1_699_990_000), action: "checkout", message: "moving from dev to main"),
            GitReflogEntry(index: 2, hash: "ccc333", shortHash: "ccc", date: nil, action: "reset", message: ""),
        ])
    }

    @Test func skipsCutLines() {
        #expect(GitReflogParser.parse("aaa\tbbb\n").isEmpty)
    }

    @Test func selectorUsesTheIndex() {
        #expect(GitReflogEntry(index: 3, hash: "", shortHash: "", date: nil, action: "", message: "").selector == "HEAD@{3}")
    }
}
