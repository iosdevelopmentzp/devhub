import Foundation

struct BaseBranchCIFailure: Equatable {
    var branch: String
    var workflows: [String]
    var subject: String?

    var title: String {
        workflows.isEmpty ? "CI of \(branch) failed" : "CI of \(branch) failed: \(workflows.joined(separator: ", "))"
    }
}
