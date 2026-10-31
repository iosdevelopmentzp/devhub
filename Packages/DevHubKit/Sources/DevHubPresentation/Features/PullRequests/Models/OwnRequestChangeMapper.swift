import Foundation
import DevHubDomain
import DevHubUI

enum OwnRequestChangeMapper {
    struct Report: Equatable {
        var title: String
        var body: String
        var outcome: ActivityEvent.Outcome
        var kind: NotificationKind
    }

    static func report(for change: OwnRequestChange, words: CodeHostWords) -> Report? {
        let reference = words.reference(change.request.iid)
        switch change {
        case .approved(let request, let approvers):
            return Report(title: "\(reference) approved by \(names(approvers))", body: request.title, outcome: .success, kind: .requestReviews)
        case .changesRequested(let request, let reviewers):
            return Report(title: "Changes requested on \(reference) by \(names(reviewers))", body: request.title, outcome: .info, kind: .requestReviews)
        case .checksFailed(let request):
            return Report(title: "\(words.checksTitle) failed on \(reference)", body: request.title, outcome: .failure, kind: .requestChecks)
        case .newComments(let request, let count, let authors):
            return Report(title: commentsTitle(count: count, authors: authors, reference: reference), body: request.title, outcome: .info, kind: .requestComments)
        case .gone:
            return nil
        }
    }

    static func report(forGone request: PullRequestSummary, state: PullRequestState, words: CodeHostWords) -> Report? {
        let reference = words.reference(request.iid)
        switch state {
        case .merged:
            return Report(title: "\(reference) merged", body: request.title, outcome: .success, kind: .requestClosed)
        case .closed:
            return Report(title: "\(reference) closed without a merge", body: request.title, outcome: .info, kind: .requestClosed)
        case .opened, .locked, .other:
            return nil
        }
    }

    private static func commentsTitle(count: Int, authors: [String], reference: String) -> String {
        let counted = CountText.count(count, "new comment", "new comments")
        guard authors.isEmpty == false else { return "\(counted) on \(reference)" }
        guard count > authors.count else { return "\(names(authors)) commented on \(reference)" }
        return "\(names(authors)) commented on \(reference) (\(counted))"
    }

    private static func names(_ names: [String]) -> String {
        guard names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
    }
}
