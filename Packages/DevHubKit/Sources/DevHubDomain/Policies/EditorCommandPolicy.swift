import Foundation

package enum EditorCommandPolicy {
    package struct Command: Hashable, Sendable {
        package let executable: String
        package let arguments: [String]

        package init(executable: String, arguments: [String]) {
            self.executable = executable
            self.arguments = arguments
        }
    }

    package static func openFile(_ path: String, line: Int?, editor: String) -> Command {
        let located = line.map { "\(path):\($0)" } ?? path
        switch editor {
        case "Xcode":
            return Command(executable: "xed", arguments: (line.map { ["--line", String($0)] } ?? []) + [path])
        case "VS Code":
            return Command(executable: "code", arguments: ["--goto", located])
        case "Cursor":
            return Command(executable: "cursor", arguments: ["--goto", located])
        case "Zed":
            return Command(executable: "zed", arguments: [located])
        default:
            return fallback(path, editor: editor)
        }
    }

    package static func fallback(_ path: String, editor: String) -> Command {
        Command(executable: "open", arguments: ["-a", appName(editor), path])
    }

    package static func appName(_ editor: String) -> String {
        editor == "VS Code" ? "Visual Studio Code" : editor
    }
}
