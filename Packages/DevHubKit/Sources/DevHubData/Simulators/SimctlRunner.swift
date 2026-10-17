import Foundation
import DevHubDomain

struct SimctlRunner: Sendable {
    let shell: ShellRunner

    @discardableResult
    func run(_ arguments: [String], allowingExit tolerated: Set<Int32> = [], failure: (String) -> any Error) async throws -> ShellResult {
        let result = try await shell.run("xcrun", ["simctl"] + arguments, cwd: nil)
        guard result.exitCode == 0 || tolerated.contains(result.exitCode) else {
            throw failure(message(for: result, arguments: arguments))
        }
        return result
    }

    private func message(for result: ShellResult, arguments: [String]) -> String {
        if result.stderr.trimmed.isEmpty == false { return result.stderr.trimmed }
        if result.stdout.trimmed.isEmpty == false { return result.stdout.trimmed }
        return "simctl \(arguments.first ?? "") exited with code \(result.exitCode)."
    }
}
