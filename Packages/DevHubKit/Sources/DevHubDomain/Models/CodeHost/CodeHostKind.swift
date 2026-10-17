import Foundation

package enum CodeHostKind: String, Codable, CaseIterable, Hashable, Sendable {
    case github
    case gitlab
}
