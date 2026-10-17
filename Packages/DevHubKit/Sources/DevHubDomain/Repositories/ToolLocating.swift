import Foundation

package protocol ToolLocating: Sendable {
    func isInstalled(_ executable: String) -> Bool
}
