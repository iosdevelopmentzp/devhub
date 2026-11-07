import Foundation

package struct ReviewerIdentity: Hashable, Sendable {
    package var username: String
    package var teams: [String] = []
    package var rule: ReviewQueueRule = .open

    package init(username: String, teams: [String] = [], rule: ReviewQueueRule = .open) {
        self.username = username
        self.teams = teams
        self.rule = rule
    }
}
