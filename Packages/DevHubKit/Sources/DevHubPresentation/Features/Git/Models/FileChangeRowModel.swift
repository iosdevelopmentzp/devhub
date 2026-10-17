import Foundation
import DevHubDomain
import DevHubUI

struct FileChangeRowModel: Identifiable, Equatable {
    let id: GitFileChange.ID
    var letter: String
    var letterTint: Tint
    var letterHint: String
    var fileName: String
    var detail: String
    var path: String
    var fullPath: String
    var folderPath: String
    var isStaged: Bool
    var stageIcon: String
    var stageHint: String
    var discardHint: String
    var discardMessage: String
    var discardTitle: String
    var areActionsEnabled: Bool
    var diff: DiffModel?

    var isExpanded: Bool {
        diff != nil
    }

    static let preview = FileChangeRowModel(
        id: "2:ExampleApp/Features/Call/CallPromptView.swift",
        letter: "M",
        letterTint: .orange,
        letterHint: "Modified",
        fileName: "CallPromptView.swift",
        detail: "ExampleApp/Features/Call",
        path: "ExampleApp/Features/Call/CallPromptView.swift",
        fullPath: "/Users/dev/example-app/ExampleApp/Features/Call/CallPromptView.swift",
        folderPath: "/Users/dev/example-app/ExampleApp/Features/Call",
        isStaged: false,
        stageIcon: "plus.circle",
        stageHint: "Stage: include in the next commit",
        discardHint: "Discard the changes in this file",
        discardMessage: "Discard the changes in CallPromptView.swift? They cannot be restored.",
        discardTitle: "Discard",
        areActionsEnabled: true,
        diff: .preview
    )
}
