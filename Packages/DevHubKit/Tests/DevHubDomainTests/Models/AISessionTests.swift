import Foundation
import Testing
@testable import DevHubDomain

@Suite struct AISessionTests {
    @Test func folderNameIsTheLastComponentOfTheWorkingFolder() {
        #expect(session(cwd: "/Users/me/Projects/DevHub").folderName == "DevHub")
    }

    @Test func resumeCommandQuotesTheFolder() {
        #expect(session(cwd: "/Users/me/My App").resumeCommand == "cd '/Users/me/My App' && claude --resume abc-123")
    }

    @Test func resumeCommandEscapesAQuoteInTheFolder() {
        #expect(session(cwd: "/Users/me/Bob's").resumeCommand == #"cd '/Users/me/Bob'\''s' && claude --resume abc-123"#)
    }

    private func session(cwd: String) -> AISession {
        AISession(
            id: "abc-123",
            title: "Session",
            lastPrompt: nil,
            cwd: cwd,
            gitBranch: nil,
            startedAt: nil,
            updatedAt: Date(timeIntervalSince1970: 0),
            folderExists: true
        )
    }
}
