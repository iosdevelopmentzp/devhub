import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct ClaudeTranscriptSessionRepositoryTests {
    private let directory: TemporaryDirectory
    private let repository: ClaudeTranscriptSessionRepository

    private static let firstID = "1F0C5E2A-0000-4000-8000-000000000001"
    private static let secondID = "1F0C5E2A-0000-4000-8000-000000000002"

    init() throws {
        directory = try TemporaryDirectory()
        repository = ClaudeTranscriptSessionRepository(root: directory.url.appendingPathComponent("projects"))
    }

    @Test func readsTranscriptsNewestFirst() async throws {
        try transcript(Self.firstID, cwd: directory.url.path, title: "Existing folder", modified: 1_000)
        try transcript(Self.secondID, cwd: "/nonexistent/\(UUID().uuidString)", title: "Missing folder", modified: 2_000)

        let sessions = await repository.sessions()

        #expect(sessions.map(\.id) == [Self.secondID, Self.firstID])
        #expect(sessions.map(\.title) == ["Missing folder", "Existing folder"])
        #expect(sessions.map(\.folderExists) == [false, true])
        #expect(sessions.first?.updatedAt == Date(timeIntervalSince1970: 2_000))
    }

    @Test func ignoresFilesThatAreNotSessionTranscripts() async throws {
        try transcript(Self.firstID, cwd: directory.url.path, title: "Session", modified: 1_000)
        _ = try directory.write(ClaudeTranscriptFixture.user, to: "projects/-Users-me-App/notes.jsonl")
        _ = try directory.write(ClaudeTranscriptFixture.user, to: "projects/-Users-me-App/\(Self.secondID).txt")
        _ = try directory.write("", to: "projects/-Users-me-App/\(UUID().uuidString).jsonl")

        let sessions = await repository.sessions()

        #expect(sessions.map(\.id) == [Self.firstID])
    }

    @Test func secondReadReturnsTheSameSessionsAndDropsRemovedFiles() async throws {
        try transcript(Self.firstID, cwd: directory.url.path, title: "First", modified: 1_000)
        let second = try transcript(Self.secondID, cwd: directory.url.path, title: "Second", modified: 2_000)

        let first = await repository.sessions()
        let again = await repository.sessions()
        try FileManager.default.removeItem(at: second)
        let afterRemoval = await repository.sessions()

        #expect(again == first)
        #expect(afterRemoval.map(\.id) == [Self.firstID])
    }

    @Test func missingRootHasNoSessions() async {
        #expect(await repository.sessions().isEmpty)
    }

    @discardableResult
    private func transcript(_ id: String, cwd: String, title: String, modified: TimeInterval) throws -> URL {
        let lines = [
            #"{"type":"user","cwd":"\#(cwd)","gitBranch":"main","timestamp":"2026-01-02T03:04:05Z"}"#,
            #"{"type":"custom-title","customTitle":"\#(title)"}"#,
        ]
        let file = try directory.write(lines.joined(separator: "\n") + "\n", to: "projects/-Users-me-App/\(id).jsonl")
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: modified)], ofItemAtPath: file.path)
        return file
    }
}
