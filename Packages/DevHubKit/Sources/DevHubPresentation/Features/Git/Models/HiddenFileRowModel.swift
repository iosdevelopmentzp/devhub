import Foundation
import DevHubDomain
import DevHubUI

struct HiddenFileRowModel: Identifiable, Equatable {
    struct FlagTag: Equatable {
        var text: String
        var hint: String
    }

    let id: GitHiddenFile.ID
    var letter: String
    var letterTint: Tint
    var letterHint: String
    var fileName: String
    var detail: String
    var path: String
    var fullPath: String
    var revealPath: String
    var canOpen: Bool
    var flags: [FlagTag]
    var hasChanges: Bool
    var trackHint: String
    var discardMessage: String
    var areActionsEnabled: Bool
    var diff: DiffModel?
    var diffText: String?

    var isExpanded: Bool {
        diff != nil
    }

    static let preview = HiddenFileRowMapper.model(
        for: GitHiddenFile(path: "ExampleApp/Config/Local.xcconfig", flags: [.skipWorktree], state: .modified),
        checkoutPath: "/Users/dev/example-app",
        isExpanded: false,
        diff: nil,
        isBusy: false,
        syntaxColors: false
    )
}
