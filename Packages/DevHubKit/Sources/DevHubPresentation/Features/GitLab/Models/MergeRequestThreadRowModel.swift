import Foundation

struct MergeRequestThreadRowModel: Identifiable, Equatable {
    let id: String
    var author: String
    var location: String?
    var locationHint: String?
    var body: String
    var repliesText: String?
    var replies: [MergeRequestNoteModel]
    var filePath: String?
    var line: Int?
    var isOnOldLine: Bool
    var canShowInDiff: Bool
    var noteURL: URL?
    var isBusy: Bool

    static let preview = MergeRequestThreadRowModel(
        id: "1",
        author: "sam",
        location: "CallPresenter.swift:42",
        locationHint: "ExampleUI/Calls/CallPresenter.swift:42",
        body: "Please move this check into the presenter.",
        repliesText: "2 replies",
        replies: [MergeRequestNoteModel(id: 0, author: "alex", body: "Done in the next commit."), MergeRequestNoteModel(id: 1, author: "sam", body: "Thanks!")],
        filePath: "ExampleUI/Calls/CallPresenter.swift",
        line: 42,
        isOnOldLine: false,
        canShowInDiff: true,
        noteURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/1842#note_501"),
        isBusy: false
    )
}
