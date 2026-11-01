import Foundation
import DevHubDomain

struct AppDefaultsSectionModel: Identifiable, Equatable {
    let id: String
    var suite: AppDefaultsSuite
    var title: String
    var detail: String
    var rows: [AppDefaultRowModel]
    var hiddenText: String?
    var emptyText: String?
}
