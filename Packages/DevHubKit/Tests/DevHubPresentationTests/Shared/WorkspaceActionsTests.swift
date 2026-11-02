import DevHubDomain
import DevHubMocks
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct WorkspaceActionsTests {
    let activity = ActivityLog(events: [], store: InMemoryKeyValueStore())
    let opener = SpyWorkspaceOpener()
    let files = SpyTextFileRepository()
    let settings = SettingsStore(values: AppSettings(terminal: "iTerm"), store: InMemoryKeyValueStore())

    @Test func openTerminalSuccessLogsInfo() async throws {
        let actions = makeActions()

        actions.openTerminal(at: "/tmp/repo")
        try await waitUntil { activity.events.isEmpty == false }

        #expect(opener.calls == [.openTerminal("iTerm", path: "/tmp/repo")])
        let event = try #require(activity.events.first)
        #expect(event.title == "Opened iTerm")
        #expect(event.detail == "/tmp/repo")
        #expect(event.outcome == .info)
    }

    @Test func openTerminalFailureLogsFailure() async throws {
        opener.openTerminalResult = "iTerm is not installed"
        let actions = makeActions()

        actions.openTerminal(at: "/tmp/repo")
        try await waitUntil { activity.events.isEmpty == false }

        let event = try #require(activity.events.first)
        #expect(event.title == "Could not open iTerm")
        #expect(event.detail == "iTerm is not installed")
        #expect(event.outcome == .failure)
    }

    @Test func runInTerminalSuccessLogsTheTitle() async throws {
        let actions = makeActions()

        actions.runInTerminal("claude --resume 1", at: "/tmp/repo", title: "Resumed session")
        try await waitUntil { activity.events.isEmpty == false }

        #expect(opener.calls == [.runInTerminal("iTerm", path: "/tmp/repo", command: "claude --resume 1")])
        let event = try #require(activity.events.first)
        #expect(event.title == "Resumed session")
        #expect(event.detail == "/tmp/repo".abbreviatingHome)
        #expect(event.outcome == .info)
    }

    @Test func runInTerminalFailureLogsFailure() async throws {
        opener.runInTerminalResult = "AppleScript failed"
        let actions = makeActions()

        actions.runInTerminal("ls", at: "/tmp/repo", title: "Listed")
        try await waitUntil { activity.events.isEmpty == false }

        #expect(activity.events.first?.title == "Could not open iTerm")
        #expect(activity.events.first?.detail == "AppleScript failed")
        #expect(activity.events.first?.outcome == .failure)
    }

    @Test func openFileLogsOnlyFailures() async throws {
        let actions = makeActions()

        actions.openFile(path: "/tmp/a.swift", line: 12)
        try await waitUntil { opener.calls.contains(.openFile("/tmp/a.swift", line: 12, editor: "Xcode")) }
        #expect(activity.events.isEmpty)

        opener.openFileResult = "xed: not found"
        actions.openFile(path: "/tmp/b.swift", line: Int?.none)
        try await waitUntil { activity.events.first?.title == "Could not open the file in Xcode" }
    }

    @Test func openInXcodeLogsOnlyFailures() async throws {
        let actions = makeActions()

        actions.openInXcode(path: "/tmp/ok", container: "App.xcworkspace")
        try await waitUntil { opener.calls.count == 1 }
        opener.openInXcodeResult = "No Xcode project"
        actions.openInXcode(path: "/tmp/bad", container: nil)
        try await waitUntil { activity.events.isEmpty == false && opener.calls.count == 2 }

        #expect(activity.events.count == 1)
        #expect(activity.events.first?.title == "Could not open Xcode")
        #expect(activity.events.first?.detail == "No Xcode project")
        #expect(opener.calls == [.openInXcode("/tmp/ok", container: "App.xcworkspace"), .openInXcode("/tmp/bad", container: nil)])
    }

    @Test func openInEditorLogsOnlyFailures() async throws {
        let actions = makeActions()

        actions.openInEditor(path: "/tmp/ok", editor: "Cursor")
        try await waitUntil { opener.calls.count == 1 }
        opener.openInEditorResult = "Cursor is not installed"
        actions.openInEditor(path: "/tmp/bad", editor: "Cursor")
        try await waitUntil { activity.events.isEmpty == false && opener.calls.count == 2 }

        #expect(opener.calls == [.openInEditor("Cursor", path: "/tmp/ok"), .openInEditor("Cursor", path: "/tmp/bad")])
        #expect(activity.events.count == 1)
        #expect(activity.events.first?.title == "Could not open Cursor")
    }

    private func makeActions() -> WorkspaceActions {
        WorkspaceActions(settings: settings, activity: activity, opener: opener, files: files)
    }

    @Test func openInEditorWritesAScratchFileAndOpensItInTheEditor() async throws {
        let actions = makeActions()
        files.scratchResult = .success("/tmp/scratch/output.log")

        actions.openInEditor(text: "$ git status\n", name: "output.log")

        try await waitUntil { opener.calls == [.openFile("/tmp/scratch/output.log", line: nil, editor: "Xcode")] }
        #expect(files.calls == [.writeScratch("$ git status\n", name: "output.log")])
    }

    @Test func saveTextWritesTheFileAndLogsIt() async throws {
        let actions = makeActions()

        actions.saveText("log", to: "/Users/alex/Desktop/build.log")
        try await waitUntil { activity.events.isEmpty == false }

        #expect(files.calls == [.write("log", path: "/Users/alex/Desktop/build.log")])
        #expect(activity.events.first?.title == "Saved build.log")
        #expect(activity.events.first?.outcome == .success)
    }

    @Test func aFailedSaveLogsTheError() async throws {
        let actions = makeActions()
        files.writeError = TestError.scripted("read-only")

        actions.saveText("log", to: "/x/build.log")
        try await waitUntil { activity.events.isEmpty == false }

        #expect(activity.events.first?.title == "Could not save build.log")
        #expect(activity.events.first?.outcome == .failure)
    }

    @Test func aFolderOpensAndAFileOrAPackageIsSelected() {
        #expect(WorkspaceActions.opensFolder(exists: true, isDirectory: true, isPackage: false))
        #expect(WorkspaceActions.opensFolder(exists: true, isDirectory: false, isPackage: false) == false)
        #expect(WorkspaceActions.opensFolder(exists: true, isDirectory: true, isPackage: true) == false)
        #expect(WorkspaceActions.opensFolder(exists: false, isDirectory: false, isPackage: false))
    }
}
