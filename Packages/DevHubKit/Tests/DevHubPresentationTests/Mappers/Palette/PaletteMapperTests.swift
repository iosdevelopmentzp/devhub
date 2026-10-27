import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct PaletteMapperTests {
    private let clean = ConfigSample.action("clean")

    private var sources: PaletteSources {
        PaletteSources(
            tabs: [TabItem(id: .feature(.git), title: "Git", systemImage: "arrow.triangle.pull", searchPrompt: nil)],
            actions: [.builtin(.terminal), .config(clean)],
            simulators: [SimulatorFixture.iPhone],
            targetID: nil,
            branches: ["main", "feature/ABC-123-login"],
            currentBranch: "main",
            worktrees: [WorktreeFixture.main, WorktreeFixture.linked],
            pullRequests: [PullRequestSummaryFixture.open],
            sessions: [AISessionFixture.session],
            favoriteSessionIDs: [],
            isKeepAwakeOn: false,
            projects: [ProjectSample.app, ProjectSample.other],
            selectedProjectID: ProjectSample.app.id,
            requestNumber: CodeHostWords.gitHub.reference
        )
    }

    private var items: [PaletteItem] {
        PaletteMapper.items(from: sources) { $0.id }
    }

    @Test func everySourceGivesItsCommands() {
        let commands = items.map(\.command)

        #expect(commands.contains(.showTab(.feature(.git))))
        #expect(commands.contains(.runAction(.builtin(.terminal))))
        #expect(commands.contains(.runAction(.config(clean))))
        #expect(commands.contains(.buildAndRun(on: SimulatorFixture.iPhone.id)))
        #expect(commands.contains(.selectTarget(SimulatorFixture.iPhone.id)))
        #expect(commands.contains(.switchBranch("feature/ABC-123-login")))
        #expect(commands.contains(.buildBranch("feature/ABC-123-login")))
        #expect(commands.contains(.createWorktree("feature/ABC-123-login")))
        #expect(commands.contains(.buildWorktree(WorktreeFixture.linked.id)))
        #expect(commands.contains(.openFolder(WorktreeFixture.linked.path)))
        #expect(commands.contains(.showPullRequest(PullRequestSummaryFixture.open.iid)))
        #expect(commands.contains(.resumeSession(command: AISessionFixture.session.terminalCommand, folder: AISessionFixture.session.cwd, title: "Resumed Claude session")))
        #expect(commands.last == .openSettings)
    }

    @Test func theCurrentBranchTheMainWorktreeAndTheTargetAreLeftOut() {
        var withTarget = sources
        withTarget.targetID = SimulatorFixture.iPhone.id
        let commands = PaletteMapper.items(from: withTarget) { $0.id }.map(\.command)

        #expect(commands.contains(.switchBranch("main")) == false)
        #expect(commands.contains(.openFolder(WorktreeFixture.main.path)) == false)
        #expect(commands.contains(.selectTarget(SimulatorFixture.iPhone.id)) == false)
    }

    @Test func aRequestTitleUsesTheHostReference() {
        #expect(items.contains { $0.title.hasPrefix("#\(PullRequestSummaryFixture.open.iid) ") })
    }

    @Test func everyWordMustMatchAndTitlePrefixesComeFirst() {
        let found = PaletteMapper.matches(items, query: "ABC-123 build")

        #expect(found.map(\.command) == [.buildBranch("feature/ABC-123-login")])
        #expect(PaletteMapper.matches(items, query: "git").first?.command == .showTab(.feature(.git)))
        #expect(PaletteMapper.matches(items, query: "nothing like this").isEmpty)
        #expect(PaletteMapper.matches(items, query: " ").count == min(items.count, PaletteMapper.limit))
    }

    @Test func keepAwakeItemNamesTheNextState() {
        var awake = sources
        awake.isKeepAwakeOn = true

        #expect(items.first { $0.command == .toggleKeepAwake }?.title == "Keep Mac awake")
        #expect(PaletteMapper.items(from: awake) { $0.id }.first { $0.command == .toggleKeepAwake }?.title == "Let the Mac sleep")
    }

    @Test func favoriteSessionsComeFirstWithAStar() {
        let second = AISessionSample.session(id: "favorite", cwd: AISessionFixture.session.cwd)
        var favored = sources
        favored.sessions = [AISessionFixture.session, second]
        favored.favoriteSessionIDs = ["favorite"]

        let sessions = PaletteMapper.items(from: favored) { $0.id }.filter { $0.section == "AI sessions" }

        #expect(sessions.map(\.id) == ["session:favorite", "session:\(AISessionFixture.session.id)"])
        #expect(sessions.first?.systemImage == "star.fill")
        #expect(sessions.first?.subtitle.hasPrefix("Favorite · ") == true)
    }

    @Test func otherProjectsCanBeSelectedWithTheirShortcut() {
        let projects = items.filter { $0.section == "Projects" }

        #expect(projects.map(\.command) == [.selectProject(ProjectSample.other.id)])
        #expect(projects.first?.title == "Switch to project \(ProjectSample.other.name)")
        #expect(projects.first?.subtitle.hasPrefix("⌃⌘2") == true)
    }
}
