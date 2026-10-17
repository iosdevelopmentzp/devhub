import Foundation

package enum InputType: String, Codable, Hashable, Sendable {
    case text
    case number
    case toggle
    case choice
    case branch
    case worktree
    case simulator
    case scheme
    case file
    case folder
}
