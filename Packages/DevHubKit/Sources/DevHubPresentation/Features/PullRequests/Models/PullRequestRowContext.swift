import Foundation
import DevHubDomain

struct PullRequestRowContext {
    var username: String?
    var scope: PullRequestScope
    var seenAt: Date?
    var now: Date
    var isMainCheckoutClean: Bool
    var ticket: TicketSettings
    var words: CodeHostWords
    var staleDays: Int
    var hiddenFiles: [String]
    var fileGroups: [PullRequestFileGroup] = []
    var watchedIDs: Set<Int>
    var people: [String] = []
    var busyPeopleIDs: Set<Int> = []
    var explanations: [Int: String] = [:]
    var explainingIDs: Set<Int> = []
    var aiProvider = AIProvider.claude
}
