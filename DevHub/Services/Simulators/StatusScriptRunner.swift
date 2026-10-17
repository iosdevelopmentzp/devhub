import Foundation

nonisolated struct StatusScriptRunner: Sendable {
    static let timeout: Duration = .seconds(5)

    let shell: ShellRunner

    func run(script: String, environment: [String: String], folder: String) async throws -> [String] {
        let box = LineBox()
        let shell = shell
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                _ = try await shell.stream(script, [], cwd: folder, environment: environment) { box.add($0) }
                return true
            }
            group.addTask {
                try await Task.sleep(for: Self.timeout)
                return false
            }
            let finished = try await group.next() ?? false
            group.cancelAll()
            guard finished else {
                throw SimulatorError(message: "status timed out")
            }
            return box.lines
        }
    }
}

nonisolated final class LineBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [String] = []

    var lines: [String] {
        lock.withLock { stored }
    }

    func add(_ line: String) {
        lock.withLock { stored.append(line) }
    }
}
