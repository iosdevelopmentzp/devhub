import Foundation

package struct CITestResult: Hashable, Sendable, Codable {
    package let className: String
    package let name: String
    package let result: String
    package let runTime: Double?
    package let message: String?

    package init(className: String, name: String, result: String, runTime: Double?, message: String?) {
        self.className = className
        self.name = name
        self.result = result
        self.runTime = runTime
        self.message = message
    }

    package var isFailure: Bool {
        result == "failure" || result == "failed" || result == "error"
    }
}
