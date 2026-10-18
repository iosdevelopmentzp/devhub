import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct CopilotSessionRepositoryTests {
    private let directory: TemporaryDirectory

    init() throws {
        directory = try TemporaryDirectory()
    }

    @Test func readsSessionFoldersWithEventsAndSkipsTheRest() async throws {
        _ = try directory.write("cwd: \(directory.url.path)\nsummary: Current", to: "1a2b/workspace.yaml")
        _ = try directory.write(#"{"type":"user.message","data":{"content":"Hi"}}"#, to: "1a2b/events.jsonl")
        _ = try directory.write("cwd: /missing/folder\nsummary: Gone", to: "3c4d/workspace.yaml")
        _ = try directory.write("", to: "3c4d/events.jsonl")
        _ = try directory.write("cwd: /repo", to: "no-events/workspace.yaml")
        _ = try directory.write("{}", to: "loose.jsonl")

        let sessions = await CopilotSessionRepository(root: directory.url).sessions()

        #expect(Set(sessions.map(\.id)) == ["1a2b", "3c4d"])
        #expect(sessions.first { $0.id == "1a2b" }?.folderExists == true)
        #expect(sessions.first { $0.id == "3c4d" }?.folderExists == false)
        #expect(sessions.allSatisfy { $0.provider == .copilot })
    }

    @Test func aMissingRootGivesNoSessions() async {
        #expect(await CopilotSessionRepository(root: directory.url.appendingPathComponent("none")).sessions().isEmpty)
    }
}
