import Foundation
import DevHubDomain

enum TestOutputParser {
    enum Line: Equatable {
        case runStarted
        case testFinished(TestCaseResult)
        case failure(TestFailure)
    }

    private static let xcTestCase = try? NSRegularExpression(pattern: #"^Test Case '(?:-\[(\S+) (\S+)\]|(\S+))' (passed|failed|skipped) \(([\d.]+) seconds\)\.?$"#)
    private static let xcTestFailure = try? NSRegularExpression(pattern: #"^(/[^:]+):(\d+): error: (?:-\[(\S+) (\S+)\]|(\S+)) : (.+)$"#)
    private static let swiftTestingCase = try? NSRegularExpression(pattern: #"^\W*Test (?:"([^"]+)"|(\S+)) (passed|failed|skipped)(?: after ([\d.]+) seconds)?"#)
    private static let swiftTestingIssue = try? NSRegularExpression(pattern: #"^\W*Test (?:"([^"]+)"|(\S+)) recorded an issue(?: at ([^:\s]+):(\d+)(?::\d+)?)?: (.+)$"#)

    static func parse(_ line: String) -> Line? {
        let trimmed = line.trimmed
        if trimmed.hasPrefix("Test Suite 'All tests' started") || trimmed.hasPrefix("Testing started") || swiftTestingRunStarted(trimmed) {
            return .runStarted
        }
        if let result = xcTestCaseResult(trimmed) { return .testFinished(result) }
        if let failure = xcTestFailureResult(trimmed) { return .failure(failure) }
        if let failure = swiftTestingIssueResult(trimmed) { return .failure(failure) }
        if let result = swiftTestingCaseResult(trimmed) { return .testFinished(result) }
        return nil
    }

    private static func swiftTestingRunStarted(_ line: String) -> Bool {
        line.range(of: #"^\W*Test run started\."#, options: .regularExpression) != nil
    }

    private static func xcTestCaseResult(_ line: String) -> TestCaseResult? {
        guard let groups = xcTestCase?.groups(in: line) else { return nil }
        let (suite, name) = suiteAndName(qualified: groups[1], method: groups[2], dotted: groups[3])
        return TestCaseResult(suite: suite, name: name, status: status(groups[4]), duration: groups[5].flatMap(TimeInterval.init))
    }

    private static func xcTestFailureResult(_ line: String) -> TestFailure? {
        guard let groups = xcTestFailure?.groups(in: line) else { return nil }
        let (suite, name) = suiteAndName(qualified: groups[3], method: groups[4], dotted: groups[5])
        let path = groups[1] ?? ""
        return TestFailure(
            test: [suite, name].compactMap { $0 }.joined(separator: "."),
            file: (path as NSString).lastPathComponent,
            path: path,
            line: groups[2].flatMap(Int.init),
            message: groups[6] ?? ""
        )
    }

    private static func swiftTestingCaseResult(_ line: String) -> TestCaseResult? {
        guard let groups = swiftTestingCase?.groups(in: line) else { return nil }
        return TestCaseResult(suite: nil, name: groups[1] ?? groups[2] ?? "", status: status(groups[3]), duration: groups[4].flatMap(TimeInterval.init))
    }

    private static func swiftTestingIssueResult(_ line: String) -> TestFailure? {
        guard let groups = swiftTestingIssue?.groups(in: line) else { return nil }
        return TestFailure(test: groups[1] ?? groups[2], file: groups[3], path: nil, line: groups[4].flatMap(Int.init), message: groups[5] ?? "")
    }

    private static func suiteAndName(qualified: String?, method: String?, dotted: String?) -> (String?, String) {
        if let method {
            return (qualified.map { String($0.split(separator: ".").last ?? Substring($0)) }, method)
        }
        let parts = (dotted ?? "").split(separator: ".", maxSplits: 1).map(String.init)
        return parts.count == 2 ? (parts[0], parts[1]) : (nil, dotted ?? "")
    }

    private static func status(_ word: String?) -> TestCaseResult.Status {
        switch word {
        case "failed": .failed
        case "skipped": .skipped
        default: .passed
        }
    }
}

private extension NSRegularExpression {
    func groups(in line: String) -> [String?]? {
        guard let match = firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { return nil }
        return (0..<match.numberOfRanges).map { Range(match.range(at: $0), in: line).map { String(line[$0]) } }
    }
}
