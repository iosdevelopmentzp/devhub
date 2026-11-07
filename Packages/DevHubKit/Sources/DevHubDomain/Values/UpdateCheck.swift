import Foundation

package enum UpdateCheck: Equatable, Sendable {
    case upToDate
    case available([UpdateCommit])
    case unknownInstalledCommit
}
