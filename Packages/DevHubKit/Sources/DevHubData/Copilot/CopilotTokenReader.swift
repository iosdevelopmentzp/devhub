import Foundation
import DevHubDomain

actor CopilotTokenReader {
    private enum KeychainRead {
        case found(String)
        case missing
    }

    private static let keychainService = "copilot-cli"
    private static let keychainTimeout: Duration = .seconds(10)

    let shell: ShellRunner
    let tools: any ToolLocating
    private var keychainTimedOut = false

    init(shell: ShellRunner, tools: any ToolLocating) {
        self.shell = shell
        self.tools = tools
    }

    func read() async throws -> String? {
        if tools.isInstalled("gh") {
            let result = try await shell.run("gh", ["auth", "token"], cwd: nil)
            if result.exitCode == 0, let token = CopilotTokenParser.parse(result.stdout) {
                return token
            }
        }
        guard keychainTimedOut == false else { return nil }
        guard let read = try await keychainText() else {
            keychainTimedOut = true
            return nil
        }
        guard case let .found(text) = read else { return nil }
        return CopilotTokenParser.parse(text)
    }

    private func keychainText() async throws -> KeychainRead? {
        let shell = shell
        let lines = LineCollector()
        return try await withThrowingTaskGroup(of: KeychainRead?.self) { group in
            group.addTask {
                let code = try await shell.stream("security", ["find-generic-password", "-s", Self.keychainService, "-w"], cwd: nil) { lines.append($0) }
                return code == 0 ? .found(lines.text) : .missing
            }
            group.addTask {
                try await Task.sleep(for: Self.keychainTimeout)
                return nil
            }
            let first = try await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
