import Foundation
import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct RedactionSubjectsMapperTests {
    @Test func theSubjectsComeFromTheRemoteTheBranchesAndThePeople() {
        let host = CodeHost(kind: .gitlab, host: "gitlab.example.com", path: "team/sub/app", webURL: URL(string: "https://gitlab.example.com/team/sub/app")!)
        let request = PullRequestSummaryFixture.request(iid: 7, source: "feature/mine", state: .opened, author: "sam", approvedBy: ["kim"], assignees: ["lee"], reviewers: ["robin"], changesRequestedBy: ["", "alex"], target: "dev")

        let subjects = RedactionSubjectsMapper.subjects(host: host, currentBranch: "feature/current", baseName: "dev", requests: [request], username: "alex", home: "/Users/alex")

        #expect(subjects.organization == "team")
        #expect(subjects.repository == "app")
        #expect(subjects.host == "gitlab.example.com")
        #expect(subjects.branches == ["dev", "feature/current", "feature/mine"])
        #expect(subjects.logins == ["alex", "kim", "lee", "robin", "sam"])
        #expect(subjects.homeFolder == "/Users/alex")
    }

    @Test func noRemoteLeavesTheRemoteSubjectsEmpty() {
        let subjects = RedactionSubjectsMapper.subjects(host: nil, currentBranch: nil, baseName: "main", requests: [], username: nil, home: "/Users/alex")

        #expect(subjects.organization == nil)
        #expect(subjects.repository == nil)
        #expect(subjects.host == nil)
        #expect(subjects.branches == ["main"])
        #expect(subjects.logins.isEmpty)
    }

    @Test func addingTheProjectNamesTheFolderUserSchemesAndBundles() {
        let project = Project(id: "p", name: "Example App", path: "/Users/alex/Projects/example-app", scheme: "ExampleApp", bundleID: "com.example.app")
        let config = ProjectConfig(name: "Example", xcode: XcodeConfig(scheme: "ExampleApp", bundleID: "com.example.app", schemes: ["ExampleAppTests"], bundleIDs: ["ExampleAppTests": "com.example.app.tests"]))

        let subjects = RedactionSubjectsMapper.adding(project: project, config: config, to: RedactionSubjects(homeFolder: "/Users/alex"))

        #expect(subjects.userName == "alex")
        #expect(subjects.projectFolder == "/Users/alex/Projects/example-app")
        #expect(subjects.projectNames == ["Example", "Example App", "example-app"])
        #expect(subjects.schemes == ["ExampleApp", "ExampleAppTests"])
        #expect(subjects.bundleIDs == ["com.example.app", "com.example.app.tests"])
    }
}
