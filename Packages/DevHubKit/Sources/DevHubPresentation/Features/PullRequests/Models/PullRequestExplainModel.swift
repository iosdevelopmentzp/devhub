import Foundation

struct PullRequestExplainModel: Equatable {
    var button: AIWriteButtonModel
    var text: AttributedString?

    static let preview = PullRequestExplainModel(
        button: .preview,
        text: AttributedString("What it changes: the call sheet asks for the price first.")
    )
}
