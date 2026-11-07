import Foundation
import DevHubUI

struct PullRequestFileGroupChipModel: Identifiable, Equatable {
    let id: String
    var title: String
    var icon: String
    var tint: Tint
    var isHidden: Bool
    var hint: String

    static let preview = PullRequestFileGroupChipModel(
        id: "Tests",
        title: "Tests 12",
        icon: "eye.slash",
        tint: .secondary,
        isHidden: true,
        hint: "12 files are in the group Tests (*Tests/*, *Tests.swift). Click to show them."
    )
}
