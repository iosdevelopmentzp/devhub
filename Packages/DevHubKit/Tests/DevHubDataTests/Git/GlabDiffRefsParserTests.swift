import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabDiffRefsParserTests {
    @Test func readsTheThreeCommits() throws {
        let data = Data(#"{"iid": 7, "diff_refs": {"base_sha": "b1", "start_sha": "s1", "head_sha": "h1"}}"#.utf8)

        #expect(try GlabDiffRefsParser.diffRefs(from: data) == GlabDiffRefsParser.DiffRefs(baseSHA: "b1", startSHA: "s1", headSHA: "h1"))
    }

    @Test func missingRefsAreAnError() {
        #expect(throws: PullRequestError.self) {
            try GlabDiffRefsParser.diffRefs(from: Data(#"{"iid": 7, "diff_refs": null}"#.utf8))
        }
    }
}
