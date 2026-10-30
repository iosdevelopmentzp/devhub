import Foundation
import DevHubDomain

struct TestRun: Equatable {
    enum Phase: Equatable {
        case running(step: String)
        case finished(TestRunReport.Status, Date)
        case notRun(String, Date)
    }

    var scheme: String
    var simulatorName: String
    var startedAt: Date
    var phase: Phase
    var passed = 0
    var failed = 0
    var skipped = 0
    var failures: [TestFailure] = []
    var issues: [BuildIssue] = []
    var resultBundlePath: String?

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    var total: Int {
        passed + failed + skipped
    }

    var finishedAt: Date? {
        switch phase {
        case .running: nil
        case .finished(_, let date), .notRun(_, let date): date
        }
    }
}
