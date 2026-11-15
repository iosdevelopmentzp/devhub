import Foundation

package enum SyntaxLanguage: String, CaseIterable, Hashable, Sendable {
    case swift

    package static let extensions: [String: SyntaxLanguage] = [
        "swift": .swift,
    ]

    package static func language(forPath path: String) -> SyntaxLanguage? {
        extensions[(path as NSString).pathExtension.lowercased()]
    }
}
