import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct AISessionRowMapperTests {
    @Test func sessionWithExistingFolder() {
        let session = AISessionFixture.session

        let model = AISessionRowMapper.model(for: session, isFavorite: false)

        #expect(model.id == session.id)
        #expect(model.title == "Fix the worktree delete confirmation")
        #expect(model.icon == "sparkles")
        #expect(model.iconTint == .orange)
        #expect(model.providerTag == TagModel("Claude", tint: .secondary))
        #expect(model.terminalTitle == "Resumed Claude session")
        #expect(model.dateText.isEmpty == false)
        #expect(model.folderPath == "/Users/dev/Projects/DevHub")
        #expect(model.folderDisplayPath == "/Users/dev/Projects/DevHub".abbreviatingHome)
        #expect(model.branchTag == TagModel("feature/worktree-delete", tint: .blue, systemImage: "arrow.triangle.branch"))
        #expect(model.statusTags.isEmpty)
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

        let model = AISessionRowMapper.model(for: session, isFavorite: false)

        #expect(model.iconTint == .secondary)
        #expect(model.branchTag == nil)
        #expect(model.statusTags == [TagModel("folder missing", tint: .red, systemImage: "folder.badge.questionmark")])
        #expect(model.canResume == false)
        #expect(model.resumeHint == "The folder of this session no longer exists")
        #expect(model.canShowFolder == false)
    }

    @Test func lastPromptEqualToTitleIsHidden() {
        var session = AISessionFixture.session
        session.lastPrompt = session.title

        #expect(AISessionRowMapper.model(for: session, isFavorite: false).lastPrompt == nil)

        session.lastPrompt = nil
        #expect(AISessionRowMapper.model(for: session, isFavorite: false).lastPrompt == nil)
    }

    @Test func aCopilotSessionResumesWithCopilot() {
        var session = AISessionFixture.session
        session.provider = .copilot

        let model = AISessionRowMapper.model(for: session, isFavorite: false)

        #expect(model.icon == "chevron.left.forwardslash.chevron.right")
        #expect(model.providerTag == TagModel("Copilot", tint: .secondary))
        #expect(model.terminalCommand == "copilot --resume 5f0c2d8e-1b7a-4c3e-9a51-0e2f6b7d9c41")
        #expect(model.terminalTitle == "Resumed Copilot session")
        #expect(model.resumeHint == "Open the terminal in DevHub and run copilot --resume")
    }

    @Test func aFavoriteHasAFilledYellowStar() {
        let favorite = AISessionRowMapper.model(for: AISessionFixture.session, isFavorite: true)
        let plain = AISessionRowMapper.model(for: AISessionFixture.session, isFavorite: false)

        #expect(favorite.isFavorite)
        #expect(favorite.favoriteIcon == "star.fill")
        #expect(favorite.favoriteTint == .yellow)
        #expect(favorite.favoriteHint == "Remove from favorites")
        #expect(plain.favoriteIcon == "star")
        #expect(plain.favoriteTint == .secondary)
    }
}
