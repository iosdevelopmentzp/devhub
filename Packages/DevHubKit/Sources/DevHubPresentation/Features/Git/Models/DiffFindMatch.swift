import Foundation

struct DiffFindMatch: Hashable {
    let path: String
    let lineID: Int
    let range: Range<Int>
    let line: Int
    let isOld: Bool
}
