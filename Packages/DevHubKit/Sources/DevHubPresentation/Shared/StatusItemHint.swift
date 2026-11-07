import DevHubDomain
import DevHubUI

enum StatusItemHint {
    static func text(for state: StatusItemState, failedRequests: [Int], onHold: [Int: [String]], words: CodeHostWords) -> String? {
        switch state {
        case .ciFailed:
            let references = failedRequests.sorted().map(words.reference)
            guard let first = references.first else { return nil }
            return references.count == 1
                ? "The \(words.checks) of your \(words.request) \(first) failed"
                : "The \(words.checks) of \(references.count) of your \(words.requests) failed: \(references.joined(separator: ", "))"
        case .ciWaiting:
            guard let iid = onHold.keys.sorted().first, let jobs = onHold[iid] else { return nil }
            let others = onHold.count - 1
            let text = "\(words.reference(iid)) waits for an approval of \(jobs.joined(separator: ", "))"
            return others > 0 ? "\(text), and \(CountText.count(others, "more \(words.request)", "more \(words.requests)"))" : text
        case .failed:
            return "Something failed. Open the panel to see it"
        case .idle, .building, .awake:
            return nil
        }
    }
}
