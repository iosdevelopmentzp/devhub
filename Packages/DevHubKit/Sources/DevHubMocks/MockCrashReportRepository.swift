import Foundation
import DevHubDomain

struct MockCrashReportRepository: CrashReportRepository {
    func reports(since: Date) async throws -> [CrashReport] {
        [MockData.crashReport]
    }

    func ownReports(processName: String, bundleID: String?, since: Date) async throws -> [CrashReport] {
        var report = MockData.crashReport
        report.processName = processName
        report.bundleID = bundleID
        report.simulatorID = nil
        report.date = Date(timeIntervalSinceNow: -600)
        return [report]
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
