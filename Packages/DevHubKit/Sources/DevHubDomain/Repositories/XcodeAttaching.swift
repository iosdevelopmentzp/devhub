import Foundation

package protocol XcodeAttaching: Sendable {
    var isTrusted: Bool { get }
    func requestTrust()
    func attach(pid: Int32, destination: AttachDestination, projectPath: String, container: String?) async throws
}
