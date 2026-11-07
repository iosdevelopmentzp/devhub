import Foundation

package enum CIJobLogPolicy {
    package static let failedStepLineLimit = 200
    package static let otherStepLineLimit = 20

    package static func text(steps: [CIJobLogStep]) -> String {
        let failed = steps.filter(\.isFailed)
        let others = steps.filter { $0.isFailed == false }
        return (failed.map { block($0, limit: failedStepLineLimit) } + others.map { block($0, limit: otherStepLineLimit) })
            .joined(separator: "\n\n")
    }

    package static func header(of step: CIJobLogStep) -> String {
        guard let code = step.exitCode, code != 0 else { return "== \(step.name)" }
        return "== \(step.name) (exit \(code))"
    }

    private static func block(_ step: CIJobLogStep, limit: Int) -> String {
        let lines = trimmedEdges(step.output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
        guard lines.isEmpty == false else { return header(of: step) }
        let dropped = max(0, lines.count - limit)
        var body = Array(lines.suffix(limit))
        if dropped > 0 {
            body.insert("… \(dropped) more \(dropped == 1 ? "line" : "lines") above", at: 0)
        }
        return ([header(of: step)] + body).joined(separator: "\n")
    }

    private static func trimmedEdges(_ lines: [String]) -> [String] {
        var kept = lines[...]
        while kept.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            kept = kept.dropFirst()
        }
        while kept.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            kept = kept.dropLast()
        }
        return Array(kept)
    }
}
