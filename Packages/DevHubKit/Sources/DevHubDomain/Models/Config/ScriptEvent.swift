import Foundation

package enum ScriptEvent: Hashable, Sendable {
    case output(String)
    case exited(Int32)
}
