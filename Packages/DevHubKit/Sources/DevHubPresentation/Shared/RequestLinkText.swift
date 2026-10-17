import Foundation
import DevHubDomain

enum RequestLinkText {

    static func pullRequest(iid: Int, title: String, url: URL?) -> String {
        ["!\(iid) \(title)", url?.absoluteString].compactMap { $0 }.joined(separator: "\n")
    }

    static func pullRequest(_ request: PullRequestSummary) -> String {
        pullRequest(iid: request.iid, title: request.title, url: request.webURL)
    }
}
