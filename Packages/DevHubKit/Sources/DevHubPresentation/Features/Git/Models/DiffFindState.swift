import Foundation

struct DiffFindState: Equatable {
    var query = ""
    var current: DiffFindMatch?

    static let initial = DiffFindState()
}
