import Foundation
import DevHubDomain

enum XcresultParser {
    private final class Node: Decodable {
        let nodeType: String?
        let name: String?
        let nodeIdentifier: String?
        let result: String?
        let durationInSeconds: Double?
        let children: [Node]?
    }

    private struct Results: Decodable {
        let testNodes: [Node]?
    }

    private struct Context {
        var target: String?
        var suite: String?
    }

    private static let bundleTypes: Set<String> = ["Unit test bundle", "UI test bundle"]

    static func cases(from data: Data) throws -> [TestResultCase] {
        guard let results = try? JSONDecoder().decode(Results.self, from: data) else {
            throw TestRunError.failed("xcresulttool returned unexpected test results.")
        }
        var cases: [TestResultCase] = []
        for node in results.testNodes ?? [] {
            collect(node, context: Context(), into: &cases)
        }
        return cases
    }

    private static func collect(_ node: Node, context: Context, into cases: inout [TestResultCase]) {
        var context = context
        switch node.nodeType {
        case let type? where bundleTypes.contains(type):
            context.target = node.name
        case "Test Suite":
            context.suite = node.name
        case "Test Case":
            cases.append(testCase(node, context: context))
            return
        default:
            break
        }
        for child in node.children ?? [] {
            collect(child, context: context, into: &cases)
        }
    }

    private static func testCase(_ node: Node, context: Context) -> TestResultCase {
        let name = node.name ?? node.nodeIdentifier ?? "test"
        var item = TestResultCase(
            identifier: node.nodeIdentifier ?? [context.suite, name].compactMap { $0 }.joined(separator: "/"),
            target: context.target,
            suite: context.suite,
            name: name,
            status: status(node.result),
            duration: node.durationInSeconds
        )
        guard item.status == .failed else { return item }
        let messages = descendants(of: node, type: "Failure Message").compactMap(\.name)
        let reference = descendants(of: node, type: "Source Code Reference").compactMap(\.name).first
        if let first = messages.first {
            if let parsed = location(first) {
                item.file = parsed.file
                item.line = parsed.line
                item.failureMessage = parsed.message
            } else {
                item.failureMessage = first
            }
        }
        if item.file == nil, let reference, let parsed = location("\(reference): ") {
            item.file = parsed.file
            item.line = parsed.line
        }
        return item
    }

    private static func location(_ text: String) -> (file: String, line: Int, message: String)? {
        guard let match = text.firstMatch(of: /^([^:\s][^:]*\.swift):(\d+): ?(.*)$/), let line = Int(match.2) else { return nil }
        return (String(match.1), line, String(match.3))
    }

    private static func descendants(of node: Node, type: String) -> [Node] {
        (node.children ?? []).flatMap { child in
            (child.nodeType == type ? [child] : []) + descendants(of: child, type: type)
        }
    }

    private static func status(_ result: String?) -> TestCaseResult.Status {
        switch result {
        case "Failed": .failed
        case "Skipped": .skipped
        default: .passed
        }
    }
}
