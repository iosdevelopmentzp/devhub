import Foundation

package enum CIFailureKind: Hashable, Sendable {
    case allFlaky(testCount: Int)
    case realTests(job: String, count: Int)
    case noTests(job: String)

    package var isFlakyOnly: Bool {
        guard case .allFlaky = self else { return false }
        return true
    }

    package var reason: String {
        switch self {
        case .allFlaky(let count):
            count == 1 ? "the failed test is flaky" : "all \(count) failed tests are flaky"
        case .realTests(let job, let count):
            count == 1 ? "\(job) failed on a test that is not flaky" : "\(job) failed on \(count) tests that are not flaky"
        case .noTests(let job):
            "\(job) failed without test results"
        }
    }
}
