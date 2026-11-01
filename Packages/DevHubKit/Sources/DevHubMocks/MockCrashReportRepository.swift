import Foundation
import DevHubDomain

struct MockCrashReportRepository: CrashReportRepository {
    func reports(since: Date) async throws -> [CrashReport] {
        [MockData.crashReport]
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
