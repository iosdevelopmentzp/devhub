import Foundation

@MainActor
final class ProjectActions {
    private let session: ProjectSession
    private let config: ConfigStore
    private let workspace: WorkspaceActing
    private let settings: SettingsStore
    private let activity: ActivityLog
    private let toaster: Toaster

    init(session: ProjectSession, config: ConfigStore, workspace: WorkspaceActing, settings: SettingsStore, activity: ActivityLog, toaster: Toaster) {
        self.session = session
        self.config = config
        self.workspace = workspace
        self.settings = settings
        self.activity = activity
        self.toaster = toaster
    }

    func revealInFinder() {
        guard let path = session.project?.path else { return }
        perform("Open in Finder", detail: path) { [workspace] in
            try await workspace.revealInFinder(path: path)
        }
    }

    func openInEditor() {
        guard let path = session.project?.path else { return }
        let editor = settings.editor
        let target = editorTarget(path: path, editor: editor)
        perform("Open in \(editor.title)", detail: target) { [workspace] in
            try await workspace.open(path: target, with: editor.applicationName)
        }
    }

    func openTerminal() {
        guard let path = session.project?.path else { return }
        openTerminal(at: path)
    }

    func openInEditor(at path: String) {
        let editor = settings.editor
        perform("Open in \(editor.title)", detail: path) { [workspace] in
            try await workspace.open(path: path, with: editor.applicationName)
        }
    }

    func openTerminal(at path: String) {
        let terminal = settings.terminal
        perform("Open in \(terminal.title)", detail: path) { [workspace] in
            try await workspace.openTerminal(at: path, terminal: terminal)
        }
    }

    func openRepository() {
        guard let link = requireRepository() else { return }
        open(link.treeURL(branch: session.branch), title: "Open repository")
    }

    func openNewRequest() {
        guard let link = requireRepository() else { return }
        guard let branch = session.branch else {
            fail("New pull request", "The project has no current branch.")
            return
        }
        let base = config.effective?.baseBranch ?? "origin/main"
        let title = link.host == .gitlab ? "New merge request" : "New pull request"
        open(link.newRequestURL(branch: branch, base: base), title: title)
    }

    func copyBranch() {
        guard let branch = session.branch else {
            fail("Copy branch", "The project has no current branch.")
            return
        }
        toaster.copy(branch, label: branch)
        activity.log("Copy branch", detail: branch, outcome: .success)
    }

    func open(_ target: String, title: String) {
        Task { _ = await openTarget(target, title: title) }
    }

    func openTarget(_ target: String, title: String) async -> Bool {
        await attempt(title, detail: target) { [workspace] in
            try await workspace.openTarget(target)
        }
    }

    func runInTerminal(_ command: String, at path: String, title: String) async -> Bool {
        let terminal = settings.terminal
        return await attempt(title, detail: command) { [workspace] in
            try await workspace.runInTerminal(command: command, at: path, terminal: terminal)
        }
    }

    func reveal(_ path: String, title: String) {
        perform(title, detail: path) { [workspace] in
            try await workspace.revealInFinder(path: path)
        }
    }

    func record(_ title: String, detail: String) {
        activity.log(title, detail: detail, outcome: .success)
    }

    func fail(_ title: String, _ message: String) {
        activity.log(title, detail: message, outcome: .failure)
        toaster.show(message, tint: .red)
    }

    private func requireRepository() -> RepositoryLink? {
        guard let link = session.repository else {
            fail("Repository", "The project has no remote called origin.")
            return nil
        }
        return link
    }

    private func editorTarget(path: String, editor: EditorApp) -> String {
        guard editor == .xcode, let container = config.effective?.container else { return path }
        let absolute = container.hasPrefix("/") ? container : path + "/" + container
        return FileManager.default.fileExists(atPath: absolute) ? absolute : path
    }

    private func perform(_ title: String, detail: String, _ work: @escaping () async throws -> Void) {
        Task { _ = await attempt(title, detail: detail, work) }
    }

    private func attempt(_ title: String, detail: String, _ work: @escaping () async throws -> Void) async -> Bool {
        do {
            try await work()
            activity.log(title, detail: detail, outcome: .success)
            return true
        } catch {
            activity.log(title, detail: error.localizedDescription, outcome: .failure)
            toaster.show("\(title) failed", tint: .red)
            return false
        }
    }
}
