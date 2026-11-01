import Foundation

package enum GitPatchScope: Hashable, Sendable {
    case staged
    case range(base: String, head: String)
}
