import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@MainActor
@Suite(.tags(.integration)) struct ConfigWatcherIntegrationTests {
    @Test func anEditInPlaceIsSeen() async throws {
        let home = try TemporaryDirectory()
        let project = try TemporaryDirectory()
        let file = try project.write("{}", to: ".devhub/project.json")
        let repository = FileConfigRepository(home: home.url, pollInterval: .milliseconds(50))
        let counter = ChangeCounter()
        let changes = repository.changes(projectPath: project.url.path)
        let task = Task {
            for await _ in changes {
                counter.increment()
            }
        }
        defer { task.cancel() }

        var checks = 0
        try await waitUntil(timeout: .seconds(20)) {
            checks += 1
            if checks % 5 == 1 {
                try? #"{ "name": "Change \#(checks)" }"#.write(to: file, atomically: false, encoding: .utf8)
            }
            return counter.value > 0
        }

        #expect(counter.value > 0)
    }
}

private final class ChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() {
        lock.withLock { count += 1 }
    }
}
