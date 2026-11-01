import Foundation

package protocol CrashReportRepository: Sendable {
    func reports(since: Date) async throws -> [CrashReport]
    func changes() -> AsyncStream<Void>
}
