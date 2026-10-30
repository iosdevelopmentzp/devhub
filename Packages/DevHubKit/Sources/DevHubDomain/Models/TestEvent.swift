import Foundation

package enum TestEvent: Sendable {
    case step(String)
    case output(String)
    case issue(BuildIssue)
    case testFinished(TestCaseResult)
    case failure(TestFailure)
    case finished(TestRunReport)
}
