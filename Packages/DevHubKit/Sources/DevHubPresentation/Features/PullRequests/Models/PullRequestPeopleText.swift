import Foundation
import DevHubDomain

enum PullRequestPeopleText {
    static func title(login: String, role: PullRequestPersonRole, adds: Bool, reference: String) -> String {
        switch (role, adds) {
        case (.reviewer, true): "Request review from \(login) on \(reference)"
        case (.reviewer, false): "Remove \(login) as reviewer of \(reference)"
        case (.assignee, true): "Assign \(reference) to \(login)"
        case (.assignee, false): "Unassign \(login) from \(reference)"
        }
    }
}
