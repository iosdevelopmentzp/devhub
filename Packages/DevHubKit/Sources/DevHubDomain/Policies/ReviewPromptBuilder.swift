import Foundation

package enum ReviewPromptBuilder {

    package static func prompt(for request: PullRequestSummary, threads: [PullRequestThread]) -> String {
        var lines = [
            "# Review threads of !\(request.iid): \(request.title)",
            "",
            "Branch `\(request.sourceBranch)` into `\(request.targetBranch)`." + (request.webURL.map { " Merge request: \($0.absoluteString)" } ?? ""),
            "",
            "Reviewers left \(threads.count) open \(threads.count == 1 ? "thread" : "threads"). Each one is below.",
            "",
        ]
        for (offset, thread) in threads.enumerated() {
            lines += block(thread, number: offset + 1)
        }
        lines += [
            "## What to do",
            "",
            "1. Fix every point above in this branch. Keep each change small and in the style of the code around it.",
            "2. When a point is wrong or needs a decision, do not change the code. Write down why instead.",
            "3. Build and run the tests the project uses.",
            "4. At the end, list each thread with one line: what you changed, or why you did not. I will post these lines as replies in GitLab.",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    package static func command(promptPath: String) -> String {
        "claude \"$(cat \(promptPath.shellQuoted))\""
    }

    private static func block(_ thread: PullRequestThread, number: Int) -> [String] {
        var lines = ["## Thread \(number)" + location(thread), "", "**\(thread.author)**:", "", quoted(thread.body), ""]
        for reply in thread.replies {
            lines += ["**\(reply.author)** replied:", "", quoted(reply.body), ""]
        }
        return lines
    }

    private static func location(_ thread: PullRequestThread) -> String {
        guard let path = thread.filePath else { return " (general comment)" }
        guard let line = thread.line else { return ": `\(path)`" }
        return ": `\(path):\(line)`" + (thread.isOnOldLine ? " (a removed line)" : "")
    }

    private static func quoted(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false).map { "> \($0)" }.joined(separator: "\n")
    }
}
