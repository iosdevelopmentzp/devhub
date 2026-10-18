import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CopilotSessionParserTests {
    private let modified = Date(timeIntervalSince1970: 1_000)
    private let events = Data((#"{"type":"user.message","data":{"content":"First ask"}}"# + "\n" + #"{"type":"user.message","data":{"content":"Last ask"}}"#).utf8)

    @Test func theSummaryIsTheTitleAndTheDatesComeFromTheWorkspace() throws {
        let workspace = """
        id: 1a2b
        cwd: /Users/dev/Projects/App
        branch: feature/login
        summary: Add the login screen
        created_at: 2026-03-24T22:25:15.706Z
        updated_at: 2026-03-24T22:27:55.993Z
        """

        let session = try #require(CopilotSessionParser.parse(id: "1a2b", workspace: workspace, events: events, modified: modified))

        #expect(session.id == "1a2b")
        #expect(session.provider == .copilot)
        #expect(session.title == "Add the login screen")
        #expect(session.lastPrompt == "Last ask")
        #expect(session.cwd == "/Users/dev/Projects/App")
        #expect(session.gitBranch == "feature/login")
        #expect(session.startedAt == ISO8601.date(from: "2026-03-24T22:25:15.706Z"))
        #expect(session.updatedAt == ISO8601.date(from: "2026-03-24T22:27:55.993Z"))
    }

    @Test func titleFallsBackToTheNameThenThePromptThenTheFolder() {
        let name = CopilotSessionParser.parse(id: "a", workspace: "cwd: /repo/App\nname: Named\nsummary: Summary", events: events, modified: modified)
        let prompt = CopilotSessionParser.parse(id: "a", workspace: "cwd: /repo/App", events: events, modified: modified)
        let folder = CopilotSessionParser.parse(id: "a", workspace: "cwd: /repo/App\nbranch: HEAD", events: Data(), modified: modified)

        #expect(name?.title == "Named")
        #expect(prompt?.title == "First ask")
        #expect(folder?.title == "App")
        #expect(folder?.gitBranch == nil)
        #expect(folder?.updatedAt == modified)
    }

    @Test func aWorkspaceWithoutAFolderIsSkipped() {
        #expect(CopilotSessionParser.parse(id: "a", workspace: "summary: Lost", events: events, modified: modified) == nil)
    }
}
