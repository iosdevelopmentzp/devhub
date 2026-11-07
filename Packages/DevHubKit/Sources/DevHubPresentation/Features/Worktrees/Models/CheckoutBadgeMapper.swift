import Foundation
import DevHubDomain
import DevHubUI

enum CheckoutBadgeMapper {
    static func buildSource(_ source: BuildSourceChoice, label: String, hasWorktree: Bool, worktrees: [Worktree]) -> CheckoutBadgeModel {
        let look: (text: String, icon: String) = switch source {
        case .main:
            (mainText(worktrees.first(where: \.isMain)), "house")
        case .worktree:
            ("Worktree · \(label)", "rectangle.stack")
        case .branch:
            hasWorktree ? ("Worktree · \(label)", "rectangle.stack") : ("Branch · \(label)", "arrow.triangle.branch")
        }
        return model(
            text: look.text,
            icon: look.icon,
            isMain: source == .main,
            hint: "Build source: \(look.text). Click to build the main checkout, a worktree or any branch. A branch without a worktree gets one on the next run."
        )
    }

    static func gitCheckout(path: String, worktree: Worktree?) -> CheckoutBadgeModel {
        let look: (text: String, icon: String, isMain: Bool) = switch worktree {
        case let worktree? where worktree.isMain:
            (mainText(worktree), "house", true)
        case let worktree?:
            ("Worktree · \(worktree.displayName)", "rectangle.stack", false)
        case nil:
            (path.abbreviatingHome, "folder", false)
        }
        return model(
            text: look.text,
            icon: look.icon,
            isMain: look.isMain,
            hint: "The actions of this tab run in this checkout: \(look.text). Click to choose another checkout."
        )
    }

    private static func mainText(_ main: Worktree?) -> String {
        guard let main else { return "Main checkout" }
        return "Main checkout · \(main.displayName)"
    }

    private static func model(text: String, icon: String, isMain: Bool, hint: String) -> CheckoutBadgeModel {
        CheckoutBadgeModel(text: text, icon: icon, tint: isMain ? .secondary : .orange, isMain: isMain, hint: hint)
    }
}
