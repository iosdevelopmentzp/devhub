import Foundation

enum NotificationSymbol: String, CaseIterable {
    case success = "✅"
    case launched = "🚀"
    case failure = "❌"
    case warning = "⚠️"
    case approved = "👍"
    case changesRequested = "✏️"
    case checksPassed = "🟢"
    case checksFailed = "🔴"
    case merged = "🎉"
    case closed = "🚫"
    case comment = "💬"
    case reviewRequest = "👀"
    case reminder = "⏰"
    case waitsForApproval = "✋"
    case rerun = "🔁"
    case stopped = "🛑"
    case inbox = "📥"
    case crash = "💥"
    case video = "🎬"

    static func title(_ title: String, symbol: NotificationSymbol?, showsEmoji: Bool) -> String {
        guard showsEmoji, let symbol else { return title }
        return "\(symbol.rawValue) \(title)"
    }
}
