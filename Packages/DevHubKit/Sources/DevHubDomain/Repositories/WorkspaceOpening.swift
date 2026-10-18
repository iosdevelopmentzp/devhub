import Foundation

package protocol WorkspaceOpening: Sendable {
    func openTerminal(_ app: String, at path: String) async -> String?
    func runInTerminal(_ app: String, at path: String, command: String) async -> String?
    func openInEditor(_ editor: String, path: String) async -> String?
    func openInXcode(_ path: String, container: String?) async -> String?
    func openFile(_ path: String, line: Int?, editor: String) async -> String?
}
