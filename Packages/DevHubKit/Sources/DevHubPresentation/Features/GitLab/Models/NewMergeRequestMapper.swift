import Foundation
import DevHubDomain

enum NewMergeRequestMapper {

    static func title(branch: String, lastSubject: String?) -> String {
        guard let key = TicketPrefix.key(in: branch) else { return lastSubject ?? "" }
        guard let lastSubject, lastSubject.isEmpty == false else { return "\(key): " }
        return lastSubject.hasPrefix(key) ? lastSubject : "\(key): \(lastSubject)"
    }

    static func description(template: String?, branch: String, subjects: [String]) -> String {
        if let template, template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return template
        }
        let ticket = TicketPrefix.key(in: branch).map { ["Ticket: \($0)"] } ?? []
        let changes = subjects.reversed().map { "- \($0)" }
        return (ticket + (ticket.isEmpty || changes.isEmpty ? [] : [""]) + changes).joined(separator: "\n")
    }

    static func model(for draft: NewMergeRequestDraft) -> NewMergeRequestFormModel {
        let isBusy = draft.isLoading || draft.isCreating
        return NewMergeRequestFormModel(
            heading: "New merge request from \(draft.sourceBranch)",
            createTitle: draft.pushPlan == .none ? "Create" : "Push & Create",
            createHint: createHint(draft),
            canCreate: isBusy == false && draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && draft.targetBranch.isEmpty == false,
            isBusy: isBusy,
            busyText: draft.isCreating ? "Creating…" : (draft.isLoading ? "Reading commits and labels…" : nil)
        )
    }

    private static func createHint(_ draft: NewMergeRequestDraft) -> String {
        switch draft.pushPlan {
        case .none:
            "Create the merge request into \(draft.targetBranch) on GitLab"
        case .push(let setUpstream):
            "Push the branch first (\(setUpstream ? "git push -u origin \(draft.sourceBranch)" : "git push")), then create the merge request into \(draft.targetBranch)"
        }
    }
}
