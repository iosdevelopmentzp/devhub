import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct PullRequestHiddenFilesTests {
    private let harness = StoreHarness(projects: [ProjectSample.app, ProjectSample.other])

    private var hidden: PullRequestHiddenFiles {
        harness.pullRequestHiddenFiles
    }

    private func key(_ project: Project) -> String {
        PullRequestsPreferenceKeys.hiddenFiles(projectID: project.id)
    }

    @Test func nothingIsHiddenAtFirst() {
        #expect(hidden.paths.isEmpty)
    }

    @Test func hiddenFilesAreSavedPerProjectAndReadBack() {
        hidden.hide(["Podfile.lock", "App.xcodeproj/project.pbxproj"])
        let reopened = StoreHarness(projects: [ProjectSample.app, ProjectSample.other], store: harness.store)

        #expect(reopened.pullRequestHiddenFiles.paths == ["Podfile.lock", "App.xcodeproj/project.pbxproj"])
        #expect(harness.store.decode([String].self, forKey: key(ProjectSample.app)) == ["App.xcodeproj/project.pbxproj", "Podfile.lock"])
    }

    @Test func unhideShowsOneFileAgainAndTheLastOneRemovesTheKey() {
        hidden.hide(["Podfile.lock", "Package.resolved"])

        hidden.unhide("Podfile.lock")
        let afterOne = hidden.paths
        hidden.unhide("Package.resolved")

        #expect(afterOne == ["Package.resolved"])
        #expect(hidden.paths.isEmpty)
        #expect(harness.store.data(forKey: key(ProjectSample.app)) == nil)
    }

    @Test func anotherProjectHasItsOwnList() {
        hidden.hide(["Podfile.lock"])

        harness.session.selectedProjectID = ProjectSample.other.id

        #expect(hidden.paths.isEmpty)
        hidden.hide(["Generated.swift"])
        harness.session.selectedProjectID = ProjectSample.app.id
        #expect(hidden.paths == ["Podfile.lock"])
    }
}
