import Foundation
import DevHubUI

struct PullRequestFileRowModel: Identifiable, Equatable {
    let id: String
    var letter: String
    var letterTint: Tint
    var letterHint: String
    var fileName: String
    var detail: String
    var path: String
    var additionsText: String
    var deletionsText: String
    var isExpanded: Bool
    var isViewed: Bool
    var diff: DiffModel?
    var highlightedLineID: Int?
    var threadCountText: String?
    var diffThreads: [Int: [DiffThreadModel]]
    var oldPath: String
    var lineComposer: LineComposerModel?

    static func scrollID(_ id: String) -> String {
        "merge-request-file:\(id)"
    }

    static let preview = PullRequestFileRowModel(
        id: "ExampleUI/Calls/CallPresenter.swift",
        letter: "M",
        letterTint: .orange,
        letterHint: "Modified",
        fileName: "CallPresenter.swift",
        detail: "ExampleUI/Calls",
        path: "ExampleUI/Calls/CallPresenter.swift",
        additionsText: "+2",
        deletionsText: "−1",
        isExpanded: true,
        isViewed: false,
        diff: .preview,
        highlightedLineID: 1,
        threadCountText: "1",
        diffThreads: [2: [.preview]],
        oldPath: "ExampleUI/Calls/CallPresenter.swift",
        lineComposer: .preview
    )
}
