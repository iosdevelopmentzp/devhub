import Foundation

struct DiffThreadModel: Identifiable, Equatable {
    let id: String
    var author: String
    var summary: String
    var repliesText: String?
    var isOpen: Bool
    var thread: ReviewThreadRowModel

    static let preview = DiffThreadModel(id: "1", author: "sam", summary: "Please move this check into the presenter.", repliesText: "2 replies", isOpen: false, thread: .preview)
}
