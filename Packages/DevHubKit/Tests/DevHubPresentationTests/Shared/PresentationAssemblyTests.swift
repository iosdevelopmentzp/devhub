import DevHubDomain
import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct PresentationAssemblyTests {
    @Test func previewBuilds() {
        let assembly = PresentationAssembly.preview()
        #expect(assembly.worktrees.worktrees.isEmpty == false)
    }

    @Test func previewHoldsTheMockState() {
        let assembly = PresentationAssembly.preview()

        #expect(assembly.worktrees.worktrees == MockData.worktrees)
        #expect(assembly.worktrees.derivedDataSizes == MockData.derivedDataSizes)
        #expect(assembly.simulators.groups == MockData.simulatorGroups)
        #expect(assembly.identity.identities == MockData.identities)
        #expect(assembly.usage.usage == MockData.usage)
        #expect(assembly.activity.events == MockData.recentEvents)
    }

    @Test func previewStartsOnTheFirstProjectAndHome() {
        let assembly = PresentationAssembly.preview()

        #expect(assembly.session.projects == MockData.projects)
        #expect(assembly.session.selectedProject == MockData.projects[0])
        #expect(assembly.navigator.selection == .home)
        #expect(assembly.settings.values == AppSettings())
        #expect(assembly.commandLog.entries.isEmpty)
        #expect(assembly.output.isVisible == false)
        #expect(assembly.layout.size == WindowLayout.defaultSize)
        #expect(assembly.toaster.text == nil)
    }

    @Test func previewWiresEveryStore() {
        let assembly = PresentationAssembly.preview()
        let stores: [AnyObject] = [
            assembly.commandLog, assembly.events, assembly.session, assembly.config, assembly.configActions, assembly.navigator, assembly.activity,
            assembly.toaster, assembly.hints, assembly.output, assembly.layout, assembly.settings,
            assembly.workspace, assembly.usage, assembly.worktrees, assembly.git, assembly.changes,
            assembly.branchPullRequest, assembly.simulators, assembly.identity, assembly.build,
            assembly.logs, assembly.messaging, assembly.claudeSessions, assembly.appActions
        ]

        #expect(Set(stores.map(ObjectIdentifier.init)).count == 25)
    }

    @Test func runsOnMainActor() {
        MainActor.assertIsolated()
    }
}
