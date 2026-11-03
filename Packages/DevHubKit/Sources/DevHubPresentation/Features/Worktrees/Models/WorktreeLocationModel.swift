import Foundation

struct WorktreeLocationModel: Equatable {
    var path: String
    var hint: String
    var canKeepInside: Bool
    var keepInsideHint: String

    static let preview = WorktreeLocationModel(
        path: "~/Projects/ExampleApp-ABC-2600-newFeature",
        hint: "Next to the project folder.",
        canKeepInside: true,
        keepInsideHint: "Add .worktrees/ to .git/info/exclude, so git does not list it. New worktrees then go to ~/Projects/ExampleApp/.worktrees. Worktrees you already have stay where they are."
    )
}
