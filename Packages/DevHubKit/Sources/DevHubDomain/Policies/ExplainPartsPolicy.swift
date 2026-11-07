import Foundation

package enum ExplainPartsPolicy {
    package static let partLimit = 5

    package static func plan(_ files: [PullRequestFileDiff], limit: Int) -> ExplainPlan {
        var parts: [[PullRequestFileDiff]] = []
        var current: [PullRequestFileDiff] = []
        var size = 0
        var leftOut: [String] = []
        for file in files {
            let fileSize = AITextPromptBuilder.patch(of: [file]).count + 1
            if current.isEmpty == false, size + fileSize > limit {
                parts.append(current)
                current = []
                size = 0
            }
            guard parts.count < partLimit else {
                leftOut.append(file.path)
                continue
            }
            current.append(file)
            size += fileSize
        }
        if current.isEmpty == false, parts.count < partLimit {
            parts.append(current)
        }
        return ExplainPlan(parts: parts, leftOut: leftOut)
    }

    package static func joined(_ answers: [String], leftOut: [String]) -> String {
        var text = answers.count == 1
            ? answers[0]
            : answers.enumerated().map { "### Part \($0.offset + 1) of \(answers.count)\n\n\($0.element)" }.joined(separator: "\n\n")
        if leftOut.isEmpty == false {
            text += "\n\n### Not explained\n\nThe diff is too large for \(partLimit) parts. These files were left out: \(leftOut.joined(separator: ", "))."
        }
        return text
    }
}
