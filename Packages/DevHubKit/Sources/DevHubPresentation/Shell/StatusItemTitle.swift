import Foundation

enum StatusItemTitle {
    static func text(usage: String?, reviewCount: Int?) -> String {
        let parts = [usage, reviewCount.flatMap { $0 > 0 ? "\($0) MR" : nil }].compactMap { $0 }
        return parts.isEmpty ? "" : " " + parts.joined(separator: " · ")
    }
}
