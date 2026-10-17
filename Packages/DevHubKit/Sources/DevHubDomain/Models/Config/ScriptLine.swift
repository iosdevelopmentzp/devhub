import Foundation

package enum ScriptLine: Hashable, Sendable {
    case plain
    case directives([ScriptDirective])
    case unknown
    case invalid(String)
}
