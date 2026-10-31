import Foundation
import DevHubDomain

struct PullRequestActionTexts: Equatable {
    let title: String
    let done: String
    let failed: String

    static func texts(for kind: PullRequestActionModel.Kind, number: Int, words: CodeHostWords) -> PullRequestActionTexts {
        let reference = words.reference(number)
        switch kind {
        case .approve:
            return PullRequestActionTexts(title: "Approve \(reference)", done: "Approved \(reference)", failed: "Cannot approve \(reference)")
        case .unapprove:
            return PullRequestActionTexts(title: "Revoke the approval of \(reference)", done: "Revoked the approval of \(reference)", failed: "Cannot revoke the approval of \(reference)")
        case .markReady:
            return PullRequestActionTexts(title: "Mark \(reference) as ready", done: "Marked \(reference) as ready", failed: "Cannot mark \(reference) as ready")
        case .markDraft:
            return PullRequestActionTexts(title: "Mark \(reference) as draft", done: "Marked \(reference) as draft", failed: "Cannot mark \(reference) as draft")
        case .rebase:
            return PullRequestActionTexts(title: "\(words.updateWord.capitalized) \(reference)", done: "\(words.updateWord.capitalized) of \(reference) started", failed: "Cannot \(words.updateWord) \(reference)")
        case .retryPipeline:
            return PullRequestActionTexts(title: "Retry the \(words.checks) of \(reference)", done: "\(words.checksTitle) of \(reference) retried", failed: "Cannot retry the \(words.checks) of \(reference)")
        case .cancelPipeline:
            return PullRequestActionTexts(title: "Cancel the \(words.checks) of \(reference)", done: "\(words.checksTitle) of \(reference) cancelled", failed: "Cannot cancel the \(words.checks) of \(reference)")
        case .cancelAutoMerge:
            return PullRequestActionTexts(title: "Cancel the auto-merge of \(reference)", done: "Cancelled the auto-merge of \(reference)", failed: "Cannot cancel the auto-merge of \(reference)")
        case .merge:
            return PullRequestActionTexts(title: "Merge \(reference)", done: "Merged \(reference)", failed: "Cannot merge \(reference)")
        case .mergeWhenPipelinePasses:
            return PullRequestActionTexts(title: "Set auto-merge for \(reference)", done: "\(reference) merges when \(words.checksPass)", failed: "Cannot set auto-merge for \(reference)")
        }
    }
}
