import Foundation

package struct TestCaseResult: Hashable, Sendable {
    package enum Status: Hashable, Sendable {
        case passed
        case failed
        case skipped
    }

    package var suite: String?
    package var name: String
    package var status: Status
    package var duration: TimeInterval?

    package init(suite: String?, name: String, status: Status, duration: TimeInterval?) {
        self.suite = suite
        self.name = name
        self.status = status
        self.duration = duration
    }
}
