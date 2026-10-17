import Foundation
import DevHubDomain

enum RequestLinkText {

    static func pullRequest(iid: Int, title: String, url: URL?, words: CodeHostWords) -> String {
        ["\(words.reference(iid)) \(title)", url?.absoluteString].compactMap { $0 }.joined(separator: "\n")
    }

    static func pullRequest(_ request: PullRequestSummary, words: CodeHostWords) -> String {
        pullRequest(iid: request.iid, title: request.title, url: request.webURL, words: words)
    }
}
