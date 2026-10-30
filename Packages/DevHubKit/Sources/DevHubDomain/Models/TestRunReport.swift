import Foundation

package struct TestRunReport: Hashable, Sendable {
    package enum Status: Hashable, Sendable {
        case passed
        case failed
    }

    package var status: Status
    package var resultBundlePath: String?

    package init(status: Status, resultBundlePath: String?) {
        self.status = status
        self.resultBundlePath = resultBundlePath
    }
}
