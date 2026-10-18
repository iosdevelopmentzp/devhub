import Foundation

package protocol ToolLocating: Sendable {
    func isInstalled(_ executable: String) -> Bool
    func path(of executable: String) -> String?
    func fileExists(atPath path: String) -> Bool
}
