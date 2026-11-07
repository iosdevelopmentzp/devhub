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
        CIJobLogPolicy.text(steps: try steps(from: data))
    }

    static func steps(from data: Data) throws -> [CIJobLogStep] {
        let steps: [Step]
        if let list = try? CircleCIJSON.decode([Step].self, from: data) {
            steps = list
        } else {
            steps = try CircleCIJSON.decode(Output.self, from: data).steps ?? []
        }
        return steps.map { step in
            CIJobLogStep(
                name: step.name ?? "Step \(step.num ?? 0)",
                exitCode: step.exitCode,
                output: JobLogTail.cleaned(step.output ?? "")
            )
        }
    }
}
