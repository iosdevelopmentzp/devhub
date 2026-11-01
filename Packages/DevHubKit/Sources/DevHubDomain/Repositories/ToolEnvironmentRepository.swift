import Foundation

package protocol ToolEnvironmentRepository: Sendable {
    func setDeveloperDir(_ path: String?) async
}
