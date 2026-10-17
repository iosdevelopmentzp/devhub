import Foundation
import DevHubDomain

struct NewMergeRequestDraft: Equatable {
    enum Origin: Hashable {
        case header
        case branch(String)
        case gitLab
    }

    var origin: Origin
    var sourceBranch: String
    var targets: [String]
    var targetBranch: String
    var title: String
    var description: String
    var availableLabels: [String]
    var labels: Set<String>
    var isDraft: Bool
    var removeSourceBranch: Bool
    var squash: Bool
    var pushPlan: CreateMergeRequestUseCase.PushPlan
    var isLoading: Bool
    var isCreating: Bool
    var error: String?

    var request: NewMergeRequest {
        NewMergeRequest(
            sourceBranch: sourceBranch,
            targetBranch: targetBranch,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description,
            labels: availableLabels.filter(labels.contains),
            isDraft: isDraft,
            removeSourceBranch: removeSourceBranch,
            squash: squash
        )
    }

    static let preview = NewMergeRequestDraft(
        origin: .gitLab,
        sourceBranch: "feature/ABC-2324-paid-call",
        targets: ["dev", "main"],
        targetBranch: "dev",
        title: "ABC-2324: Paid call payment",
        description: "Ticket: ABC-2324\n\n- ABC-2324: Paid call payment",
        availableLabels: ["bugfix", "feature", "tech"],
        labels: ["feature"],
        isDraft: false,
        removeSourceBranch: true,
        squash: false,
        pushPlan: .push(setUpstream: true),
        isLoading: false,
        isCreating: false,
        error: nil
    )
}
