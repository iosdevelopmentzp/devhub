import Foundation
import DevHubDomain

struct MockXcodeAttacher: XcodeAttaching {
    var isTrusted: Bool { true }

    func requestTrust() {}

    func attach(pid: Int32, simulatorUDID: String, projectPath: String) async throws {}
}
