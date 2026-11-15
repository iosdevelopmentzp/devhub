import Foundation

package enum SyntaxState: Hashable, Sendable {
    case code
    case blockComment(depth: Int)
    case multilineString(hashes: Int)
}
