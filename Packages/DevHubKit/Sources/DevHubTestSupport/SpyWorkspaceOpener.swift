import DevHubDomain
import Foundation

package final class SpyWorkspaceOpener: WorkspaceOpening, @unchecked Sendable {
    package enum Call: Hashable {
        case openTerminal(String, path: String)
        case runInTerminal(String, path: String, command: String)
        case openInEditor(String, path: String)
        case openInXcode(String)
        case openFile(String, line: Int?)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _openTerminalResult: String? = nil
    private var _runInTerminalResult: String? = nil
    private var _openInEditorResult: String? = nil
    private var _openInXcodeResult: String? = nil
    private var _openFileResult: String? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var openTerminalResult: String? {
        get { lock.withLock { _openTerminalResult } }
        set { lock.withLock { _openTerminalResult = newValue } }
    }

    package var runInTerminalResult: String? {
        get { lock.withLock { _runInTerminalResult } }
        set { lock.withLock { _runInTerminalResult = newValue } }
    }

    package var openInEditorResult: String? {
        get { lock.withLock { _openInEditorResult } }
        set { lock.withLock { _openInEditorResult = newValue } }
    }

    package var openInXcodeResult: String? {
        get { lock.withLock { _openInXcodeResult } }
        set { lock.withLock { _openInXcodeResult = newValue } }
    }

    package func openTerminal(_ app: String, at path: String) async -> String? {
        record(.openTerminal(app, path: path)) { _openTerminalResult }
    }

    package func runInTerminal(_ app: String, at path: String, command: String) async -> String? {
        record(.runInTerminal(app, path: path, command: command)) { _runInTerminalResult }
    }

    package func openInEditor(_ editor: String, path: String) async -> String? {
        record(.openInEditor(editor, path: path)) { _openInEditorResult }
    }

    package func openInXcode(_ path: String) async -> String? {
        record(.openInXcode(path)) { _openInXcodeResult }
    }

    package var openFileResult: String? {
        get { lock.withLock { _openFileResult } }
        set { lock.withLock { _openFileResult = newValue } }
    }

    package func openFile(_ path: String, line: Int?) async -> String? {
        record(.openFile(path, line: line)) { _openFileResult }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
