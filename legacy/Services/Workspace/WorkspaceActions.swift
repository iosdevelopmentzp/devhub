import Foundation

nonisolated protocol WorkspaceActing: Sendable {
    func revealInFinder(path: String) async throws
    func open(path: String, with application: String) async throws
    func openTerminal(at path: String, terminal: TerminalApp) async throws
    func runInTerminal(command: String, at path: String, terminal: TerminalApp) async throws
    func openTarget(_ target: String) async throws
}

nonisolated struct MockWorkspaceActions: WorkspaceActing {
    func revealInFinder(path: String) async throws {}
    func open(path: String, with application: String) async throws {}
    func openTerminal(at path: String, terminal: TerminalApp) async throws {}
    func runInTerminal(command: String, at path: String, terminal: TerminalApp) async throws {}
    func openTarget(_ target: String) async throws {}
}
