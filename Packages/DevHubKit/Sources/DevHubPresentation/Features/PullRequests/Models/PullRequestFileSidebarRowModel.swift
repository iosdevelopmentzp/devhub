import Foundation
import DevHubUI

struct PullRequestFileSidebarRowModel: Identifiable, Equatable {
    let id: String
    var letter: String
    var letterTint: Tint
    var fileName: String
    var folder: String
    var path: String
    var additionsText: String
    var deletionsText: String
    var isViewed: Bool
    var isExpanded: Bool
    var isChanged: Bool
    var threadCountText: String?
    var hint: String

    static let preview = PullRequestFileSidebarRowModel(
        id: "ExampleUI/Calls/CallPresenter.swift",
        letter: "M",
        letterTint: .orange,
        fileName: "CallPresenter.swift",
        folder: "ExampleUI/Calls",
        path: "ExampleUI/Calls/CallPresenter.swift",
        additionsText: "+2",
        deletionsText: "−1",
        isViewed: false,
        isExpanded: true,
        isChanged: true,
        threadCountText: "1",
        hint: "ExampleUI/Calls/CallPresenter.swift. Click to show its diff."
    )
}
