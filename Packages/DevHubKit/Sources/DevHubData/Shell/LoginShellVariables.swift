import Foundation
import DevHubDomain

actor LoginShellVariables {
    let shell: ShellRunner
    let environment: [String: String]
    let timeout: Duration
    private var timedOut = false

    init(shell: ShellRunner, environment: [String: String], timeout: Duration) {
        self.shell = shell
        self.environment = environment
        self.timeout = timeout
    }

    func read(_ names: [String]) async -> [String: String] {
        let names = names.filter(LoginShellVariablesParser.isValidName)
        guard timedOut == false, names.isEmpty == false else { return [:] }
        guard let text = await output(of: LoginShellVariablesParser.script(names)) else {
            timedOut = true
            return [:]
        }
        return LoginShellVariablesParser.variables(in: text, names: names)
    }

    private func output(of script: String) async -> String? {
        let shell = shell
        let environment = environment
        let timeout = timeout
        let lines = LineCollector()
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                let code = try? await shell.stream("zsh", ["-lc", script], cwd: nil, environment: environment) { lines.append($0) }
                return code == nil ? "" : lines.text
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
