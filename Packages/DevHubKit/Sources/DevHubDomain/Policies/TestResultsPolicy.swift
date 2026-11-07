import Foundation

package enum TestResultsPolicy {
    package static let slowestLimit = 10

    package static func failed(_ cases: [TestResultCase]) -> [TestResultCase] {
        cases.filter { $0.status == .failed }
    }

    package static func slowest(_ cases: [TestResultCase]) -> [TestResultCase] {
        let timed = cases.filter { ($0.duration ?? 0) > 0 }
        return Array(timed.sorted { ($0.duration ?? 0) > ($1.duration ?? 0) }.prefix(slowestLimit))
    }

    package static func failures(_ cases: [TestResultCase]) -> [TestFailure] {
        failed(cases).map { item in
            TestFailure(test: item.title, file: item.file, path: item.path, line: item.line, message: item.failureMessage ?? "Failed")
        }
    }

    package static func onlyTests(_ cases: [TestResultCase]) -> [String] {
        failed(cases).compactMap(\.onlyTestingID)
    }

    package static func attachments(_ attachments: [TestAttachment], of item: TestResultCase) -> [TestAttachment] {
        attachments.filter { $0.testIdentifier == item.identifier }
    }
}
