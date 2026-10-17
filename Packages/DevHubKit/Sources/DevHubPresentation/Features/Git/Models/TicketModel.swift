import Foundation

struct TicketModel: Equatable, Hashable {
    var key: String
    var url: URL?
    var hint: String

    static let preview = TicketModel(key: "ABC-2324", url: URL(string: "https://jira.example.com/browse/ABC-2324"), hint: "Open ABC-2324 in the tracker")
}
