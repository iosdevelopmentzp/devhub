import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct NewMergeRequestMapperTests {
    @Test(arguments: [
        ("feature/ABC-9-login", "Add the form", "ABC-9: Add the form"),
        ("feature/ABC-9-login", "ABC-9: Add the form", "ABC-9: Add the form"),
        ("feature/ABC-9-login", nil, "ABC-9: "),
        ("fix/crash", "Fix the crash", "Fix the crash"),
        ("fix/crash", nil, ""),
    ] as [(String, String?, String)])
    func titleStartsWithTheTicket(branch: String, subject: String?, title: String) {
        #expect(NewMergeRequestMapper.title(branch: branch, lastSubject: subject) == title)
    }

    @Test func theTemplateWins() {
        #expect(NewMergeRequestMapper.description(template: "## What\n", branch: "feature/ABC-9", subjects: ["a"]) == "## What\n")
    }

    @Test func withoutATemplateTheTicketAndTheCommitsOldestFirst() {
        #expect(NewMergeRequestMapper.description(template: "  ", branch: "feature/ABC-9", subjects: ["second", "first"]) == "Ticket: ABC-9\n\n- first\n- second")
        #expect(NewMergeRequestMapper.description(template: nil, branch: "fix/crash", subjects: ["only"]) == "- only")
        #expect(NewMergeRequestMapper.description(template: nil, branch: "feature/ABC-9", subjects: []) == "Ticket: ABC-9")
    }

    @Test func theButtonSaysWhenItPushes() {
        var draft = NewMergeRequestDraft.preview
        #expect(NewMergeRequestMapper.model(for: draft).createTitle == "Push & Create")
        #expect(NewMergeRequestMapper.model(for: draft).createHint.contains("git push -u <remote> feature/ABC-2324-paid-call"))

        draft.pushPlan = .none
        #expect(NewMergeRequestMapper.model(for: draft).createTitle == "Create")
    }

    @Test func anEmptyTitleOrBusyFormCannotCreate() {
        var draft = NewMergeRequestDraft.preview
        #expect(NewMergeRequestMapper.model(for: draft).canCreate)

        draft.title = "  "
        #expect(NewMergeRequestMapper.model(for: draft).canCreate == false)

        draft = .preview
        draft.isLoading = true
        #expect(NewMergeRequestMapper.model(for: draft).canCreate == false)
        #expect(NewMergeRequestMapper.model(for: draft).busyText == "Reading commits and labels…")

        draft.isLoading = false
        draft.isCreating = true
        #expect(NewMergeRequestMapper.model(for: draft).busyText == "Creating…")
    }
}
