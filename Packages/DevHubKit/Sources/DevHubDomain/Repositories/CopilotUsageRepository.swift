import Foundation

package protocol CopilotUsageRepository: Sendable {
    func fetch() async throws -> CopilotUsage?
}
