import Foundation

package struct UpdateStatus: Codable, Equatable, Sendable {
    package var phase: UpdatePhase
    package var startedAt: Date
    package var commit: String?
    package var message: String?

    package init(phase: UpdatePhase, startedAt: Date, commit: String? = nil, message: String? = nil) {
        self.phase = phase
        self.startedAt = startedAt
        self.commit = commit
        self.message = message
    }
}
