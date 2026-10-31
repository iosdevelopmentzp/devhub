import Foundation
import DevHubDomain

enum CircleCIJobOutputParser {
    private struct Step: Decodable {
        let num: Int?
        let name: String?
        let exitCode: Int?
        let output: String?
    }

    private struct Output: Decodable {
        let steps: [Step]?
    }

    static func log(from data: Data) throws -> String {
        let steps: [Step]
        if let list = try? CircleCIJSON.decode([Step].self, from: data) {
            steps = list
        } else {
            steps = try CircleCIJSON.decode(Output.self, from: data).steps ?? []
        }
        let text = steps.map(block).joined(separator: "\n\n")
        return JobLogTail.text(from: Data(text.utf8))
    }

    private static func block(_ step: Step) -> String {
        var header = "== \(step.name ?? "Step \(step.num ?? 0)")"
        if let code = step.exitCode, code != 0 {
            header += " (exit \(code))"
        }
        let output = (step.output ?? "").trimmingCharacters(in: .newlines)
        return output.isEmpty ? header : header + "\n" + output
    }
}
