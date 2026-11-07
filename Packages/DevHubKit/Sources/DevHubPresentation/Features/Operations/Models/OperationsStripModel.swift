import Foundation

struct OperationsStripModel: Equatable {
    var rows: [OperationStripModel]
    var moreText: String?

    static let preview = OperationsStripModel(rows: [.preview], moreText: "2 more in the footer list")
}
