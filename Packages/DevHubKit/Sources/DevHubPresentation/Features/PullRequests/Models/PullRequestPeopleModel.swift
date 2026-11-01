import Foundation
import DevHubDomain

struct PullRequestPeopleModel: Equatable {
    struct Option: Identifiable, Equatable {
        let id: String
        var title: String
        var isSelected: Bool
    }

    struct Menu: Identifiable, Equatable {
        let id: PullRequestPersonRole
        var title: String
        var icon: String
        var hint: String
        var options: [Option]
        var emptyText: String?
    }

    var menus: [Menu]
    var isBusy: Bool

    static let preview = PullRequestPeopleModel(
        menus: [
            Menu(id: .reviewer, title: "Reviewers 2", icon: "person.2.badge.plus", hint: "Add or remove reviewers", options: [Option(id: "sam", title: "sam", isSelected: true), Option(id: "kim", title: "kim", isSelected: false)], emptyText: nil),
            Menu(id: .assignee, title: "Assignees 1", icon: "person.crop.circle.badge.checkmark", hint: "Add or remove assignees", options: [Option(id: "alex", title: "alex (you)", isSelected: true)], emptyText: nil),
        ],
        isBusy: false
    )
}
