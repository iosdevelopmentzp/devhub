import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct ScriptsStoreTests {
    private let activity = ActivityLog(events: [])
    private let script = ScriptAction(id: "lint", title: "Lint", subtitle: "SwiftLint", fileName: "lint.sh", systemImage: "checkmark", lastRun: nil)

    @Test func runMarksTheScriptRunningThenLogs() async throws {
        let store = ScriptsStore(scripts: [script], activity: activity)

        store.run(script)

        #expect(store.isRunning(script.id))
        try await waitUntil(timeout: .seconds(5)) { store.isRunning(script.id) == false }
        #expect(store.scripts.first?.lastRun != nil)
        #expect(activity.events.first?.title == "Ran Lint")
        #expect(activity.events.first?.detail == "lint.sh")
        #expect(activity.events.first?.outcome == .success)
    }

    @Test func aRunningScriptIsNotStartedTwice() async throws {
        let store = ScriptsStore(scripts: [script], activity: activity)

        store.run(script)
        store.run(script)

        try await waitUntil(timeout: .seconds(5)) { store.isRunning(script.id) == false }
        #expect(activity.events.count == 1)
    }
}
