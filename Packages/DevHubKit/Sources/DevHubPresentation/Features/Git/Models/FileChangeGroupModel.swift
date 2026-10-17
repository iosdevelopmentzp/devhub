import Foundation
import DevHubDomain
import DevHubUI

struct FileChangeGroupModel: Identifiable, Equatable {
    let id: GitFileChange.Area
    var title: String
    var action: GroupAction?
    var isActionEnabled: Bool
    var changes: [GitFileChange]

    static let preview = FileChangeGroupModel(
        id: .unstaged,
        title: "Changes 1",
        action: GroupAction(title: "Stage All", kind: .stageAll),
        isActionEnabled: true,
        changes: [
            GitFileChange(path: "ExampleApp/Features/Call/CallPromptView.swift", originalPath: nil, area: .unstaged, kind: .modified)
        ]
    )
}
