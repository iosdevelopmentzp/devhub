import Foundation

struct MergeRequestNoteModel: Identifiable, Equatable {
    let id: Int
    var author: String
    var body: String
}
