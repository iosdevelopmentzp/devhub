import Foundation

package enum AppDefaultValue: Hashable, Sendable {
    case string(String)
    case integer(Int)
    case float(Double)
    case bool(Bool)
}
