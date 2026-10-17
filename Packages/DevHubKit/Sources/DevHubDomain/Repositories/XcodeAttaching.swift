import Foundation

package protocol XcodeAttaching: Sendable {
    var isTrusted: Bool { get }
    func requestTrust()
    func attach(pid: Int32, simulatorUDID: String, projectPath: String) async throws
}
