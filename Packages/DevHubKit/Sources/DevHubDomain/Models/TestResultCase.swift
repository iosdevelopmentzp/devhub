import Foundation

package struct TestResultCase: Hashable, Sendable {
    package var identifier: String
    package var target: String?
    package var suite: String?
    package var name: String
    package var status: TestCaseResult.Status
    package var duration: TimeInterval?
    package var failureMessage: String?
    package var file: String?
    package var path: String?
    package var line: Int?

    package init(
        identifier: String,
        target: String?,
        suite: String?,
        name: String,
        status: TestCaseResult.Status,
        duration: TimeInterval?,
        failureMessage: String? = nil,
        file: String? = nil,
        path: String? = nil,
        line: Int? = nil
    ) {
        self.identifier = identifier
        self.target = target
        self.suite = suite
        self.name = name
        self.status = status
        self.duration = duration
        self.failureMessage = failureMessage
        self.file = file
        self.path = path
        self.line = line
    }

    package var title: String {
        [suite, name].compactMap { $0 }.joined(separator: ".")
    }

    package var onlyTestingID: String? {
        guard let target, target.isEmpty == false else { return nil }
        let test = identifier.hasSuffix("()") ? String(identifier.dropLast(2)) : identifier
        return "\(target)/\(test)"
    }
}
