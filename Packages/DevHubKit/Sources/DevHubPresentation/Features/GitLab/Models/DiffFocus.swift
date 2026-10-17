import Foundation

struct DiffFocus: Equatable {
    let requestID: Int
    let path: String
    let line: Int
    let isOld: Bool
}
