import Foundation

struct TestSlowRowModel: Identifiable, Equatable {
    let id: String
    var title: String
    var durationText: String
    var path: String?
    var line: Int?

    static let preview = TestSlowRowModel(id: "FeedTests/testNewestPostFirst()", title: "FeedTests.testNewestPostFirst()", durationText: "1.8 s", path: nil, line: nil)
}
