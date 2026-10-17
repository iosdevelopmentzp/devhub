import Foundation

package protocol ToolLocating: Sendable {
    func isInstalled(_ executable: String) -> Bool
    func fileExists(atPath path: String) -> Bool
}
