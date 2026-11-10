import Foundation

struct DiffFindModel: Equatable {
    var query: String
    var matches: [DiffFindMatch]
    var currentIndex: Int?
    var countText: String?
    var canStep: Bool

    static let preview = DiffFindModel(
        query: "value",
        matches: [DiffFindMatch(path: "ExampleUI/Calls/CallPresenter.swift", lineID: 2, range: 9..<14, line: 42, isOld: false)],
        currentIndex: 0,
        countText: "1 of 1",
        canStep: true
    )
}
