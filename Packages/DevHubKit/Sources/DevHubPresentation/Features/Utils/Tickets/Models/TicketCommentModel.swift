import Foundation

struct TicketCommentModel: Identifiable, Equatable {
    let id: String
    var author: String
    var dateText: String?
    var body: String

    static let preview = TicketCommentModel(id: "1", author: "Sam", dateText: "2 days ago", body: "Happens on iOS 18 too. The request fails with a timeout.")
}
