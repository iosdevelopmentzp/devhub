import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct AISessionRowMapperTests {
    @Test func sessionWithExistingFolder() {
        let session = AISessionFixture.session

        let model = AISessionRowMapper.model(for: session)

        #expect(model.id == session.id)
        #expect(model.title == "Fix the worktree delete confirmation")
        #expect(model.icon == "sparkles")
        #expect(model.iconTint == .orange)
        #expect(model.dateText.isEmpty == false)
        #expect(model.folderPath == "/Users/dev/Projects/DevHub")
        #expect(model.folderDisplayPath == "/Users/dev/Projects/DevHub".abbreviatingHome)
        #expect(model.branchTag == TagModel("feature/worktree-delete", tint: .blue, systemImage: "arrow.triangle.branch"))
        #expect(model.statusTags.isEmpty)
        #expect(model.hasTags)
        #expect(model.lastPrompt == "Now run the build again")
        #expect(model.resumeCommand == session.resumeCommand)
        #expect(model.terminalCommand == "claude --resume 5f0c2d8e-1b7a-4c3e-9a51-0e2f6b7d9c41")
        #expect(model.canResume)
        #expect(model.resumeHint == "Open the terminal in DevHub and run claude --resume")
        #expect(model.canShowFolder)
    }

    @Test func sessionWithMissingFolder() {
        var session = AISessionFixture.session
        session.folderExists = false
        session.gitBranch = nil

        let model = AISessionRowMapper.model(for: session)

        #expect(model.iconTint == .secondary)
        #expect(model.branchTag == nil)
        #expect(model.statusTags == [TagModel("folder missing", tint: .red, systemImage: "folder.badge.questionmark")])
        #expect(model.hasTags)
        #expect(model.canResume == false)
        #expect(model.resumeHint == "The folder of this session no longer exists")
        #expect(model.canShowFolder == false)
    }

    @Test func lastPromptEqualToTitleIsHidden() {
        var session = AISessionFixture.session
        session.lastPrompt = session.title

        #expect(AISessionRowMapper.model(for: session).lastPrompt == nil)

        session.lastPrompt = nil
        #expect(AISessionRowMapper.model(for: session).lastPrompt == nil)
    }

    @Test func noBranchAndExistingFolderHasNoTags() {
        var session = AISessionFixture.session
        session.gitBranch = nil

        #expect(AISessionRowMapper.model(for: session).hasTags == false)
    }
}
