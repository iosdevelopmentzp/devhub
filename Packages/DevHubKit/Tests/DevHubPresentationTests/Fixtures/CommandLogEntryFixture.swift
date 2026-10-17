import DevHubDomain
import Foundation
@testable import DevHubPresentation

enum CommandLogEntryFixture {
    static let startedAt = Date(timeIntervalSince1970: 1_000)

    static let finished = CommandLog.Entry(
        id: UUID(),
        command: "git -C ~/Projects/ExampleApp fetch --prune",
        cwd: "/Users/dev/Projects/ExampleApp",
        kind: .action,
        startedAt: startedAt,
        finishedAt: startedAt.addingTimeInterval(2.5),
        exitCode: 0,
        error: nil,
        lines: ["From gitlab.example.com:top/live", " * [new branch] feature/gifts"],
        droppedLines: 0
    )

    static let read = CommandLog.Entry(
        id: UUID(),
        command: "git status --porcelain",
        cwd: nil,
        kind: .read,
        startedAt: startedAt,
        finishedAt: startedAt.addingTimeInterval(0.1),
        exitCode: 0,
        error: nil,
        lines: [],
        droppedLines: 0
    )

    static func lines(_ count: Int) -> [String] {
        (0..<count).map { "line \($0)" }
    }
}
