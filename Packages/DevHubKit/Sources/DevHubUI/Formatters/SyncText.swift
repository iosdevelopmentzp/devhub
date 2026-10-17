import Foundation

package enum SyncText {

    package static func ahead(_ n: Int) -> String {
        "↑\(n)"
    }

    package static func behind(_ n: Int) -> String {
        "↓\(n)"
    }

    package static func text(ahead: Int, behind: Int) -> String {
        var parts: [String] = []
        if ahead > 0 { parts.append(self.ahead(ahead)) }
        if behind > 0 { parts.append(self.behind(behind)) }
        return parts.joined(separator: " ")
    }
}
