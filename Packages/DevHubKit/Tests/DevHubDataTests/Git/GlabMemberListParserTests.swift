import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabMemberListParserTests {
    @Test func readsTheActiveUsernamesOnce() throws {
        let data = Data(#"[{"username":"sam","state":"active"},{"username":"lee","state":"blocked"},{"username":"alex"},{"username":"sam","state":"active"}]"#.utf8)

        #expect(try GlabMemberListParser.usernames(from: data) == ["alex", "sam"])
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: PullRequestError.self) {
            try GlabMemberListParser.usernames(from: Data("not json".utf8))
        }
    }
}
