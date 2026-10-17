import Foundation
import DevHubDomain

struct MockWorkspaceOpener: WorkspaceOpening {

    func openTerminal(_ app: String, at path: String) async -> String? {
        nil
    }

    func runInTerminal(_ app: String, at path: String, command: String) async -> String? {
        nil
    }

    func openInEditor(_ editor: String, path: String) async -> String? {
        nil
    }

    func openInXcode(_ path: String) async -> String? {
        nil
    }

    func openFile(_ path: String, line: Int?) async -> String? {
        nil
    }
}
