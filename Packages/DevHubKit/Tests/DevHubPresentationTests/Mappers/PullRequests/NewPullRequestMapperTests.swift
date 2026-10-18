import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct NewPullRequestMapperTests {
    @Test(arguments: [
        ("feature/ABC-9-login", "Add the form", "ABC-9: Add the form"),
        ("feature/ABC-9-login", "ABC-9: Add the form", "ABC-9: Add the form"),
        ("feature/ABC-9-login", nil, "ABC-9: "),
        ("fix/crash", "Fix the crash", "Fix the crash"),
        ("fix/crash", nil, ""),
    ] as [(String, String?, String)])
    func titleStartsWithTheTicket(branch: String, subject: String?, title: String) {
        #expect(NewPullRequestMapper.title(branch: branch, lastSubject: subject, ticket: .standard) == title)
    }

    @Test func theTemplateWins() {
        #expect(NewPullRequestMapper.description(template: "## What\n", branch: "feature/ABC-9", subjects: ["a"], ticket: .standard) == "## What\n")
    }

    @Test func withoutATemplateTheTicketAndTheCommitsOldestFirst() {
        #expect(NewPullRequestMapper.description(template: "  ", branch: "feature/ABC-9", subjects: ["second", "first"], ticket: .standard) == "Ticket: ABC-9\n\n- first\n- second")
        #expect(NewPullRequestMapper.description(template: nil, branch: "fix/crash", subjects: ["only"], ticket: .standard) == "- only")
        #expect(NewPullRequestMapper.description(template: nil, branch: "feature/ABC-9", subjects: [], ticket: .standard) == "Ticket: ABC-9")
    }

    @Test func onlyGitLabShowsTheMergeOptions() {
        #expect(NewPullRequestMapper.model(for: .preview, words: .gitLab).showsMergeOptions)
        #expect(NewPullRequestMapper.model(for: .preview, words: .gitHub).showsMergeOptions == false)
    }

    @Test func theButtonSaysWhenItPushes() {
        var draft = NewPullRequestDraft.preview
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).createTitle == "Push & Create")
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).createHint.contains("git push -u <remote> feature/ABC-2324-paid-call"))

        draft.pushPlan = .none
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).createTitle == "Create")
    }

    @Test func anEmptyTitleOrBusyFormCannotCreate() {
        var draft = NewPullRequestDraft.preview
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).canCreate)

        draft.title = "  "
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).canCreate == false)

        draft = .preview
        draft.isLoading = true
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).canCreate == false)
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).busyText == "Reading commits and labels…")

        draft.isLoading = false
        draft.isCreating = true
        #expect(NewPullRequestMapper.model(for: draft, words: .gitLab).busyText == "Creating…")
    }
}
