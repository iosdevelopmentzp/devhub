import Foundation
import DevHubDomain

enum PullRequestPeopleMapper {
    static func model(summary: PullRequestSummary, context: PullRequestRowContext) -> PullRequestPeopleModel? {
        guard canEdit(summary, username: context.username) else { return nil }
        return PullRequestPeopleModel(
            menus: [
                menu(.reviewer, current: summary.reviewers, people: context.people, username: context.username, words: context.words),
                menu(.assignee, current: summary.assignees, people: context.people, username: context.username, words: context.words),
            ],
            isBusy: context.busyPeopleIDs.contains(summary.id)
        )
    }

    static func canEdit(_ summary: PullRequestSummary, username: String?) -> Bool {
        guard summary.state == .opened else { return false }
        return summary.permissions.canMerge || (username != nil && summary.author == username)
    }

    private static func menu(_ role: PullRequestPersonRole, current: [String], people: [String], username: String?, words: CodeHostWords) -> PullRequestPeopleModel.Menu {
        let others = people.filter { current.contains($0) == false }
        let options = (current + others).map { login in
            PullRequestPeopleModel.Option(id: login, title: login == username ? "\(login) (you)" : login, isSelected: current.contains(login))
        }
        let noun = role == .reviewer ? "Reviewers" : "Assignees"
        return PullRequestPeopleModel.Menu(
            id: role,
            title: current.isEmpty ? noun : "\(noun) \(current.count)",
            icon: role == .reviewer ? "person.2.badge.plus" : "person.crop.circle.badge.checkmark",
            hint: "Add or remove \(noun.lowercased()) of this \(words.request). A check mark shows who is on it now.",
            options: options,
            emptyText: options.isEmpty ? "No people found in this project" : nil
        )
    }
}
