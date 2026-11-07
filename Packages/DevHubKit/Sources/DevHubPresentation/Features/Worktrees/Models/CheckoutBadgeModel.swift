import Foundation
import DevHubDomain
import DevHubUI

struct CheckoutBadgeModel: Equatable {
    var text: String
    var icon: String
    var tint: Tint
    var isMain: Bool
    var hint: String

    static let preview = CheckoutBadgeModel(
        text: "Worktree · feature/login-flow",
        icon: "rectangle.stack",
        tint: .orange,
        isMain: false,
        hint: "Build source: Worktree · feature/login-flow. Click to build the main checkout, a worktree or any branch. A branch without a worktree gets one on the next run."
    )
}
