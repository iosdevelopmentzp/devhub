import Foundation

struct ReviewThreadRowModel: Identifiable, Equatable {
    let id: String
    var author: String
    var timeText: String?
    var location: String?
    var locationHint: String?
    var body: AttributedString
    var repliesText: String?
    var replies: [PullRequestNoteModel]
    var filePath: String?
    var line: Int?
    var isOnOldLine: Bool
    var canShowInDiff: Bool
    var noteURL: URL?
    var isBusy: Bool

    static let preview = ReviewThreadRowModel(
        id: "1",
        author: "sam",
        timeText: "3 hr. ago",
        location: "CallPresenter.swift:42",
        locationHint: "ExampleUI/Calls/CallPresenter.swift:42",
        body: CommentText.attributed("Please move this check into the presenter.\n\nThe view should not know about `isPaid`; the presenter already has the account state."),
        repliesText: "2 replies",
        replies: [
            PullRequestNoteModel(id: 0, author: "alex", timeText: "2 hr. ago", body: CommentText.attributed("Done in the next commit.")),
            PullRequestNoteModel(id: 1, author: "sam", timeText: "1 hr. ago", body: CommentText.attributed("Thanks!")),
        ],
        filePath: "ExampleUI/Calls/CallPresenter.swift",
        line: 42,
        isOnOldLine: false,
        canShowInDiff: true,
        noteURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/1842#note_501"),
        isBusy: false
    )
}
