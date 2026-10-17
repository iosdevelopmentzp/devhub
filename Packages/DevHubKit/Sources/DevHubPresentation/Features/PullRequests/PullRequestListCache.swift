import Foundation
import DevHubDomain

struct PullRequestListCache {
    struct Page {
        let requests: [PullRequestSummary]
        let username: String
        let nextCursor: String?
        let loadedAt: Date
    }

    private var pages: [PullRequestQuery: Page] = [:]

    func page(for query: PullRequestQuery) -> Page? {
        pages[query]
    }

    mutating func remember(_ page: Page, for query: PullRequestQuery) {
        pages[query] = page
    }

    mutating func clear() {
        pages = [:]
    }
}
