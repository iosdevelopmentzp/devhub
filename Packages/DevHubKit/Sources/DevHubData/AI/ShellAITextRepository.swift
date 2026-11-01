import Foundation
import DevHubDomain

struct ShellAITextRepository: AITextRepository {
    static let notFoundExit: Int32 = 127
    static let errorLineLimit = 6

    let shell: ShellRunner
    let folder: URL
    let home: URL

    func generate(prompt: String, command: String, cwd: String?) async throws -> String {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("prompt-\(UUID().uuidString).md")
        try prompt.write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: file) }
        let output = OutputLines()
        let status = try await shell.stream(
            "/bin/sh",
            ["-c", AITextCommandPolicy.script(template: command, promptPath: file.path)],
            cwd: cwd,
            environment: ["PATH": Self.searchPath(home: home, inherited: ProcessInfo.processInfo.environment["PATH"])],
            onLine: { output.add($0) }
        )
        try Task.checkCancellation()
        return try Self.answer(status: status, lines: output.lines, tool: AITextCommandPolicy.tool(of: command))
    }

    static func answer(status: Int32, lines: [String], tool: String) throws -> String {
        guard status == 0 else {
            if status == notFoundExit {
                throw AITextError.notInstalled(tool)
            }
            let tail = lines.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }.suffix(errorLineLimit)
            throw AITextError.command(tail.isEmpty ? "\(tool) exited with code \(status)." : tail.joined(separator: "\n"))
        }
        let text = AITextAnswerParser.clean(lines.joined(separator: "\n"))
        guard text.isEmpty == false else { throw AITextError.emptyAnswer }
        return text
    }

    static func searchPath(home: URL, inherited: String?) -> String {
        let own = [".local/bin", ".claude/local", ".npm-global/bin"].map { home.appendingPathComponent($0).path }
        return (own + ["/opt/homebrew/bin", "/usr/local/bin", inherited ?? "/usr/bin:/bin:/usr/sbin:/sbin"]).joined(separator: ":")
    }
}

private final class OutputLines: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [String] = []

    var lines: [String] {
        lock.withLock { stored }
    }

    func add(_ line: String) {
        lock.withLock { stored.append(line) }
    }
}
