import Foundation

enum StatusItemTitle {
    static func text(usage: String?, reviewCount: Int?, words: CodeHostWords) -> String {
        let parts = [usage, reviewCount.flatMap { $0 > 0 ? "\($0) \(words.shortRequest)" : nil }].compactMap { $0 }
        return parts.isEmpty ? "" : " " + parts.joined(separator: " · ")
    }
}
