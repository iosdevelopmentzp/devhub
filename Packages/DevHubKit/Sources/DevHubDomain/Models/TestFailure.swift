import Foundation

package struct TestFailure: Hashable, Sendable {
    package var test: String?
    package var file: String?
    package var path: String?
    package var line: Int?
    package var message: String

    package init(test: String?, file: String?, path: String?, line: Int?, message: String) {
        self.test = test
        self.file = file
        self.path = path
        self.line = line
        self.message = message
    }
}
