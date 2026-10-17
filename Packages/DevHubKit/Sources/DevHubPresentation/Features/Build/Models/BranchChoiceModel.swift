import Foundation
import DevHubDomain
import DevHubUI

struct BranchChoiceModel: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var detail: String

    static let preview = BranchChoiceModel(name: "feature/login-flow", detail: "local · has a checkout")
}
