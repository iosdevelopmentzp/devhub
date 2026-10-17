import Foundation

struct PullRequestNoteModel: Identifiable, Equatable {
    let id: Int
    var author: String
    var body: String
}
