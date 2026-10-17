import Foundation
import DevHubDomain

struct PullRequestActionTexts: Equatable {
    let done: String
    let failed: String

    static func texts(for kind: PullRequestActionModel.Kind, number: Int, words: CodeHostWords) -> PullRequestActionTexts {
        let reference = words.reference(number)
        switch kind {
        case .approve:
            return PullRequestActionTexts(done: "Approved \(reference)", failed: "Cannot approve \(reference)")
        case .unapprove:
            return PullRequestActionTexts(done: "Revoked the approval of \(reference)", failed: "Cannot revoke the approval of \(reference)")
        case .markReady:
            return PullRequestActionTexts(done: "Marked \(reference) as ready", failed: "Cannot mark \(reference) as ready")
        case .markDraft:
            return PullRequestActionTexts(done: "Marked \(reference) as draft", failed: "Cannot mark \(reference) as draft")
        case .rebase:
            return PullRequestActionTexts(done: "\(words.updateWord.capitalized) of \(reference) started", failed: "Cannot \(words.updateWord) \(reference)")
        case .retryPipeline:
            return PullRequestActionTexts(done: "\(words.checksTitle) of \(reference) retried", failed: "Cannot retry the \(words.checks) of \(reference)")
        case .cancelPipeline:
            return PullRequestActionTexts(done: "\(words.checksTitle) of \(reference) cancelled", failed: "Cannot cancel the \(words.checks) of \(reference)")
        case .cancelAutoMerge:
            return PullRequestActionTexts(done: "Cancelled the auto-merge of \(reference)", failed: "Cannot cancel the auto-merge of \(reference)")
        case .merge:
            return PullRequestActionTexts(done: "Merged \(reference)", failed: "Cannot merge \(reference)")
        case .mergeWhenPipelinePasses:
            return PullRequestActionTexts(done: "\(reference) merges when \(words.checksPass)", failed: "Cannot set auto-merge for \(reference)")
        }
    }
}
