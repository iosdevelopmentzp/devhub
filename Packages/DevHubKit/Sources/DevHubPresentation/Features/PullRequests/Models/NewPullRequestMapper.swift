import Foundation
import DevHubDomain

enum NewPullRequestMapper {

    static func title(branch: String, lastSubject: String?, ticket: TicketSettings) -> String {
        guard let key = TicketPrefix.key(in: branch, ticket: ticket) else { return lastSubject ?? "" }
        guard let lastSubject, lastSubject.isEmpty == false else { return "\(key): " }
        return lastSubject.hasPrefix(key) ? lastSubject : "\(key): \(lastSubject)"
    }

    static func description(template: String?, branch: String, subjects: [String], ticket: TicketSettings) -> String {
        if let template, template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return template
        }
        let lines = TicketPrefix.key(in: branch, ticket: ticket).map { ["Ticket: \($0)"] } ?? []
        let changes = subjects.reversed().map { "- \($0)" }
        return (lines + (lines.isEmpty || changes.isEmpty ? [] : [""]) + changes).joined(separator: "\n")
    }

    static func model(for draft: NewPullRequestDraft) -> NewPullRequestFormModel {
        let isBusy = draft.isLoading || draft.isCreating
        return NewPullRequestFormModel(
            heading: "New merge request from \(draft.sourceBranch)",
            createTitle: draft.pushPlan == .none ? "Create" : "Push & Create",
            createHint: createHint(draft),
            canCreate: isBusy == false && draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && draft.targetBranch.isEmpty == false,
            isBusy: isBusy,
            busyText: draft.isCreating ? "Creating…" : (draft.isLoading ? "Reading commits and labels…" : nil)
        )
    }

    private static func createHint(_ draft: NewPullRequestDraft) -> String {
        switch draft.pushPlan {
        case .none:
            "Create the merge request into \(draft.targetBranch) on GitLab"
        case .push(let setUpstream):
            "Push the branch first (\(setUpstream ? "git push -u <remote> \(draft.sourceBranch)" : "git push")), then create the merge request into \(draft.targetBranch)"
        }
    }
}
