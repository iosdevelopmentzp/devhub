import Foundation
import DevHubDomain

enum RequestLinkText {

    static func mergeRequest(iid: Int, title: String, url: URL?) -> String {
        ["!\(iid) \(title)", url?.absoluteString].compactMap { $0 }.joined(separator: "\n")
    }

    static func mergeRequest(_ request: MergeRequestSummary) -> String {
        mergeRequest(iid: request.iid, title: request.title, url: request.webURL)
    }
}
