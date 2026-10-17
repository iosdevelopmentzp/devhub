import Foundation
import DevHubDomain
import DevHubUI

struct CommitFileRowModel: Identifiable, Equatable {
    let id: CommitFileKey
    var letter: String
    var letterTint: Tint
    var letterHint: String
    var fileName: String
    var detail: String
    var path: String
    var diff: DiffModel?

    var isExpanded: Bool {
        diff != nil
    }

    static let preview = CommitFileRowModel(
        id: CommitFileKey(hash: "a1b2c3d4e5f6", path: "ExampleApp/Features/Call/CallPromptView.swift"),
        letter: "M",
        letterTint: .orange,
        letterHint: "Modified",
        fileName: "CallPromptView.swift",
        detail: "ExampleApp/Features/Call",
        path: "ExampleApp/Features/Call/CallPromptView.swift",
        diff: .preview
    )
}
