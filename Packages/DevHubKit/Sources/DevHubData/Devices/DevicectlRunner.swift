import Foundation
import DevHubDomain

struct DevicectlRunner: Sendable {
    let shell: ShellRunner
    let outputFolder: URL

    @discardableResult
    func run(_ arguments: [String], failure: (String) -> any Error) async throws -> ShellResult {
        let result = try await shell.run("xcrun", ["devicectl"] + arguments, cwd: nil)
        guard result.exitCode == 0 else { throw failure(message(for: result, arguments: arguments)) }
        return result
    }

    func json(_ arguments: [String], failure: (String) -> any Error) async throws -> Data {
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        let file = outputFolder.appendingPathComponent("\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        try await run(arguments + ["--json-output", file.path], failure: failure)
        guard let data = FileManager.default.contents(atPath: file.path) else {
            throw failure("devicectl \(arguments.prefix(3).joined(separator: " ")) wrote no JSON output.")
        }
        return data
    }

    private func message(for result: ShellResult, arguments: [String]) -> String {
        if result.stderr.trimmed.isEmpty == false { return result.stderr.trimmed }
        if result.stdout.trimmed.isEmpty == false { return result.stdout.trimmed }
        return "devicectl \(arguments.prefix(3).joined(separator: " ")) exited with code \(result.exitCode)."
    }
}
