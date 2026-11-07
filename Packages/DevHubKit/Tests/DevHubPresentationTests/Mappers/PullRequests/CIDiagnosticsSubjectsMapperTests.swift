import Foundation
import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct CIDiagnosticsSubjectsMapperTests {
    @Test func theSubjectsComeFromTheRemoteTheBranchesAndThePeople() {
        let host = CodeHost(kind: .gitlab, host: "gitlab.example.com", path: "team/sub/app", webURL: URL(string: "https://gitlab.example.com/team/sub/app")!)
        let request = PullRequestSummaryFixture.request(iid: 7, source: "feature/mine", state: .opened, author: "sam", approvedBy: ["kim"], assignees: ["lee"], reviewers: ["robin"], changesRequestedBy: ["", "alex"], target: "dev")

        let subjects = CIDiagnosticsSubjectsMapper.subjects(host: host, currentBranch: "feature/current", baseName: "dev", requests: [request], username: "alex", home: "/Users/alex")

        #expect(subjects.organization == "team")
        #expect(subjects.repository == "app")
        #expect(subjects.host == "gitlab.example.com")
        #expect(subjects.branches == ["dev", "feature/current", "feature/mine"])
        #expect(subjects.logins == ["alex", "kim", "lee", "robin", "sam"])
        #expect(subjects.homeFolder == "/Users/alex")
    }

    @Test func noRemoteLeavesTheRemoteSubjectsEmpty() {
        let subjects = CIDiagnosticsSubjectsMapper.subjects(host: nil, currentBranch: nil, baseName: "main", requests: [], username: nil, home: "/Users/alex")

        #expect(subjects.organization == nil)
        #expect(subjects.repository == nil)
        #expect(subjects.host == nil)
        #expect(subjects.branches == ["main"])
        #expect(subjects.logins.isEmpty)
    }
}
