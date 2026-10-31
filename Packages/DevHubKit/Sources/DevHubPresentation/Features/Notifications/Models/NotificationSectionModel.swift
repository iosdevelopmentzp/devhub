import Foundation
import DevHubDomain
import DevHubUI

struct NotificationSectionModel: Identifiable, Equatable {
    let id: Date
    var title: String
    var rows: [ActivityRowModel]

    static let preview = NotificationSectionModel(id: .now, title: "Today", rows: [.preview])
}
