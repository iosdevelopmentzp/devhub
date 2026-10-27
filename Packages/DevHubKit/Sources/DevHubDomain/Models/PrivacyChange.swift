import Foundation

package enum PrivacyChange: String, CaseIterable, Hashable, Sendable {
    case grant
    case revoke
    case reset
}
