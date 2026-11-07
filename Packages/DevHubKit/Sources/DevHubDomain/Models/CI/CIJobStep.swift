import Foundation

package struct CIJobStep: Hashable, Sendable, Codable, Identifiable {
    package let index: Int
    package let name: String
    package let status: CheckStatus
    package let duration: TimeInterval?
    package let exitCode: Int?

    package init(index: Int, name: String, status: CheckStatus, duration: TimeInterval?, exitCode: Int?) {
        self.index = index
        self.name = name
        self.status = status
        self.duration = duration
        self.exitCode = exitCode
    }

    package var id: Int {
        index
    }

    package var isFailed: Bool {
        status == .failed || (exitCode ?? 0) != 0
    }
}
