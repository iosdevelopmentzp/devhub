import Foundation
import DevHubDomain
import DevHubUI

struct TodayItemModel: Identifiable, Equatable {
    let id: String
    var icon: String
    var tint: Tint
    var title: String
    var detail: String?
    var target: TodayTarget

    static let preview = TodayItemModel(id: "review", icon: "eye.fill", tint: .blue, title: "2 pull requests wait for your review", detail: nil, target: .pullRequests(.reviewing))
}
