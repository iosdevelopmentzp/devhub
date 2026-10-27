import Foundation

package struct BuildIssue: Hashable, Sendable {
    package enum Severity: Hashable, Sendable {
        case error
        case warning
    }

    package let severity: Severity
    package let path: String?
    package let line: Int?
    package let column: Int?
    package let message: String

    package init(severity: Severity, path: String?, line: Int?, column: Int?, message: String) {
        self.severity = severity
        self.path = path
        self.line = line
        self.column = column
        self.message = message
    }
}
