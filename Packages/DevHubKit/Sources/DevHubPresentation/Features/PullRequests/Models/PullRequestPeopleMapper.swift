import Foundation
import DevHubDomain

enum PullRequestPeopleMapper {
    static func model(summary: PullRequestSummary, context: PullRequestRowContext) -> PullRequestPeopleModel? {
        guard canEdit(summary, username: context.username) else { return nil }
        return PullRequestPeopleModel(
            menus: [
                menu(.reviewer, current: summary.reviewers, people: context.people, currentTeams: summary.requestedTeams, teams: context.teams, username: context.username, words: context.words),
                menu(.assignee, current: summary.assignees, people: context.people, currentTeams: [], teams: [], username: context.username, words: context.words),
            ],
            isBusy: context.busyPeopleIDs.contains(summary.id)
        )
    }

    static func canEdit(_ summary: PullRequestSummary, username: String?) -> Bool {
        guard summary.state == .opened else { return false }
        return summary.permissions.canMerge || (username != nil && summary.author == username)
    }

    private static func menu(_ role: PullRequestPersonRole, current: [String], people: [String], currentTeams: [String], teams: [String], username: String?, words: CodeHostWords) -> PullRequestPeopleModel.Menu {
        let others = people.filter { current.contains($0) == false }
        let options = (current + others).map { login in
            PullRequestPeopleModel.Option(id: login, title: login == username ? "\(login) (you)" : login, isSelected: current.contains(login))
        }
        let otherTeams = teams.filter { currentTeams.contains($0) == false }
        let teamOptions = (currentTeams + otherTeams).map { team in
            PullRequestPeopleModel.Option(id: team, title: "\(team) (team)", isSelected: currentTeams.contains(team))
        }
        let count = current.count + currentTeams.count
        let noun = role == .reviewer ? "Reviewers" : "Assignees"
        return PullRequestPeopleModel.Menu(
            id: role,
            title: count == 0 ? noun : "\(noun) \(count)",
            icon: role == .reviewer ? "person.2.badge.plus" : "person.crop.circle.badge.checkmark",
            hint: "Add or remove \(noun.lowercased()) of this \(words.request). A check mark shows who is on it now.",
            options: options,
            teams: teamOptions,
            emptyText: options.isEmpty && teamOptions.isEmpty ? "No people found in this project" : nil
        )
    }
}
