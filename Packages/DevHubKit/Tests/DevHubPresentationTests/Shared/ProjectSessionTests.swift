import DevHubDomain
import DevHubMocks
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ProjectSessionTests {
    private let store = InMemoryKeyValueStore()
    private let events = AppEvents()
    private let detector = SpyProjectDetector()
    private let changes = ChangeCounter()
    private let token: SubscriptionToken

    init() {
        let changes = changes
        token = events.subscribe { event in
            guard case .projectChanged = event else { return }
            changes.count += 1
        }
    }

    @Test func selectsTheSavedProject() {
        let session = makeSession(selected: ProjectFixture.devHub.id)

        #expect(session.selectedProjectID == "devhub")
        #expect(session.selectedProject == ProjectFixture.devHub)
    }

    @Test func unknownOrMissingSelectionFallsBackToTheFirstProject() {
        #expect(makeSession(selected: "gone").selectedProject == ProjectFixture.exampleApp)
        #expect(makeSession(selected: nil).selectedProject == ProjectFixture.exampleApp)
    }

    @Test func addNewProjectAppendsSelectsAndSaves() throws {
        let session = makeSession(selected: nil, projects: [ProjectFixture.exampleApp])

        session.add(ProjectFixture.devHub)

        #expect(session.projects == [ProjectFixture.exampleApp, ProjectFixture.devHub])
        #expect(session.selectedProjectID == "devhub")
        #expect(changes.count == 1)
        let saved = try #require(store.decode([Project].self, forKey: "app.projects"))
        #expect(saved == [ProjectFixture.exampleApp, ProjectFixture.devHub])
        #expect(store.string(forKey: "app.selectedProject") == "devhub")
    }

    @Test func addExistingPathSelectsTheExistingProject() {
        let session = makeSession(selected: nil)
        let duplicate = Project(id: "other-id", name: "Copy", path: ProjectFixture.devHub.path, scheme: "", bundleID: "")

        session.add(duplicate)

        #expect(session.projects.count == 2)
        #expect(session.selectedProjectID == "devhub")
    }

    @Test func addProjectAtFolderAsksTheDetector() {
        let session = makeSession(selected: nil)
        let folder = URL(fileURLWithPath: "/Users/dev/Projects/New")

        session.addProject(at: folder)

        #expect(detector.calls == [.project(folder)])
        #expect(session.selectedProject.path == "/Users/dev/Projects/New")
    }

    @Test func redetectTakesTheSchemeAndBundleIDFromTheDetector() throws {
        let session = makeSession(selected: nil)
        detector.projectResult = { folder in
            Project(id: "other", name: "Other", path: folder.path, scheme: "ExampleApp Dev", bundleID: "com.example.app.dev")
        }

        let found = try #require(session.redetect(id: ProjectFixture.exampleApp.id))

        #expect(detector.calls == [.project(URL(fileURLWithPath: ProjectFixture.exampleApp.path))])
        #expect(found.id == ProjectFixture.exampleApp.id)
        #expect(found.name == ProjectFixture.exampleApp.name)
        #expect(found.scheme == "ExampleApp Dev")
        #expect(found.bundleID == "com.example.app.dev")
        #expect(session.selectedProject == found)
        #expect(changes.count == 1)
    }

    @Test func redetectOfAnUnknownProjectDoesNothing() {
        let session = makeSession(selected: nil)

        #expect(session.redetect(id: "gone") == nil)
        #expect(detector.calls.isEmpty)
    }

    @Test func removeKeepsAtLeastOneProject() {
        let session = makeSession(selected: nil, projects: [ProjectFixture.exampleApp])

        session.remove(id: ProjectFixture.exampleApp.id)

        #expect(session.projects == [ProjectFixture.exampleApp])
    }

    @Test func removingTheSelectedProjectSelectsTheFirst() {
        let session = makeSession(selected: ProjectFixture.devHub.id)

        session.remove(id: ProjectFixture.devHub.id)

        #expect(session.projects == [ProjectFixture.exampleApp])
        #expect(session.selectedProjectID == "example-app")
        #expect(changes.count == 1)
    }

    @Test func removingAnotherProjectKeepsTheSelection() {
        let session = makeSession(selected: ProjectFixture.devHub.id)

        session.remove(id: ProjectFixture.exampleApp.id)

        #expect(session.selectedProjectID == "devhub")
        #expect(changes.count == 0)
    }

    @Test func updateOfSchemeOrBundleOfSelectedProjectPostsProjectChanged() {
        let session = makeSession(selected: nil)
        var scheme = ProjectFixture.exampleApp
        scheme.scheme = "ExampleApp Dev"
        var bundle = scheme
        bundle.bundleID = "com.example.app.dev"

        session.update(scheme)
        session.update(bundle)

        #expect(changes.count == 2)
        #expect(session.selectedProject == bundle)
    }

    @Test func updateOfOtherFieldsDoesNotPost() {
        let session = makeSession(selected: nil)
        var renamed = ProjectFixture.exampleApp
        renamed.name = "Top Live"

        session.update(renamed)

        #expect(changes.count == 0)
        #expect(session.selectedProject.name == "Top Live")
        #expect(store.decode([Project].self, forKey: "app.projects")?.first?.name == "Top Live")
    }

    @Test func updateOfAnotherProjectDoesNotPost() {
        let session = makeSession(selected: nil)
        var other = ProjectFixture.devHub
        other.scheme = "Other"

        session.update(other)

        #expect(changes.count == 0)
        #expect(session.projects[1].scheme == "Other")
    }

    @Test func updateOfUnknownProjectIsIgnored() {
        let session = makeSession(selected: nil)
        let unknown = Project(id: "unknown", name: "X", path: "/x", scheme: "X", bundleID: "x")

        session.update(unknown)

        #expect(session.projects == [ProjectFixture.exampleApp, ProjectFixture.devHub])
    }

    @Test func switchSearchSavesAndRestoresTextPerFeature() {
        let session = makeSession(selected: nil)
        session.searchText = "login"

        session.switchSearch(from: .feature(.git), to: .feature(.logs))
        #expect(session.searchText == "")
        session.searchText = "error"
        session.switchSearch(from: .feature(.logs), to: .feature(.git))

        #expect(session.searchText == "login")
        session.switchSearch(from: .feature(.git), to: .feature(.logs))
        #expect(session.searchText == "error")
    }

    @Test func matchesSearchIsCaseInsensitiveOverEveryField() {
        let session = makeSession(selected: nil)

        #expect(session.matchesSearch("anything"))
        session.searchText = "   "
        #expect(session.matchesSearch("anything"))
        session.searchText = " LOGIN "
        #expect(session.matchesSearch("feature/login", "subject"))
        #expect(session.matchesSearch("subject", "Login screen"))
        #expect(session.matchesSearch("feature/gifts", "subject") == false)
        #expect(session.matchesSearch() == false)
    }

    @Test func selectingAProjectPostsOnceAndSaves() {
        let session = makeSession(selected: nil)

        session.selectedProjectID = "devhub"
        session.selectedProjectID = "devhub"

        #expect(changes.count == 1)
        #expect(store.string(forKey: "app.selectedProject") == "devhub")
    }

    private func makeSession(selected: Project.ID?) -> ProjectSession {
        makeSession(selected: selected, projects: [ProjectFixture.exampleApp, ProjectFixture.devHub])
    }

    private func makeSession(selected: Project.ID?, projects: [Project]) -> ProjectSession {
        ProjectSession(projects: projects, selectedProjectID: selected, store: store, events: events, detector: detector)
    }
}

private final class ChangeCounter {
    var count = 0
}
