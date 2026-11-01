import Foundation

package enum AITextPromptBuilder {
    package static let patchLimit = 60_000

    package static func commitMessage(patch: String, recentSubjects: [String], branch: String?) -> String {
        [
            "Write a git commit message for the staged changes below.",
            "",
            "Rules:",
            "- The first line is a summary of at most 72 characters.",
            "- Follow the style of the recent commit subjects of this repository, including a prefix such as feat: or fix: when they use one.",
            "- When the change needs more words, add an empty line and a short body that says what changed and why. Wrap it at 72 characters.",
            "- Use plain English. Do not invent facts that the diff does not show.",
            "- Output only the commit message: no quotes, no code fences, no comments.",
            "",
            "Branch: \(branch ?? "unknown")",
            "",
            "Recent commit subjects:",
            list(recentSubjects),
            "",
            "Staged diff:",
            fenced(limited(patch)),
        ].joined(separator: "\n")
    }

    package static func pullRequest(patch: String, commits: [String], template: String, currentTitle: String, source: String, target: String, noun: String) -> String {
        [
            "Write the title and the description of a \(noun) for the changes below.",
            "",
            "Rules:",
            "- Output the title on the first line, then an empty line, then the description in Markdown.",
            "- The title is at most 72 characters. Keep the ticket key of the current title when it has one, for example \"ABC-123: Short summary\".",
            "- When a template is given, keep its headings and fill in each section. Write \"None\" in a section that does not apply.",
            "- Say what changes and why, and how to test it when the diff shows it. Use plain English. Do not invent facts.",
            "- Output only the title and the description, without a code fence around them.",
            "",
            "Source branch: \(source)",
            "Target branch: \(target)",
            "Current title: \(currentTitle)",
            "",
            "Commits:",
            list(commits),
            "",
            "Template:",
            template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(none)" : template,
            "",
            "Diff:",
            fenced(limited(patch)),
        ].joined(separator: "\n")
    }

    package static func explain(title: String, description: String, files: [PullRequestFileDiff], changedSinceReview: [String], noun: String) -> String {
        var sections = ["## What it changes", "## Risky places"]
        if changedSinceReview.isEmpty == false {
            sections.append("## Changed since my review")
        }
        sections.append("## What to check")
        return [
            "Explain this \(noun) to a reviewer.",
            "",
            "Write short Markdown with these sections: \(sections.joined(separator: ", ")).",
            "Name files and functions. Use plain English. Do not invent facts that the diff does not show.",
            changedSinceReview.isEmpty ? "" : "Under \"Changed since my review\", describe only these files: \(changedSinceReview.joined(separator: ", ")).",
            "",
            "Title: \(title)",
            "",
            "Description:",
            description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(none)" : description,
            "",
            "Diff:",
            fenced(limited(patch(of: files))),
        ].joined(separator: "\n")
    }

    package static func patch(of files: [PullRequestFileDiff]) -> String {
        files.map { file in
            (["--- a/\(file.oldPath)", "+++ b/\(file.path)"] + (file.isTooLarge ? ["(diff too large, \(file.additions) added and \(file.deletions) removed lines)"] : file.diff.lines))
                .joined(separator: "\n")
        }
        .joined(separator: "\n")
    }

    package static func limited(_ patch: String) -> String {
        guard patch.count > patchLimit else { return patch }
        return String(patch.prefix(patchLimit)) + "\n… (the rest of the diff is cut: \(patch.count - patchLimit) more characters)"
    }

    private static func list(_ items: [String]) -> String {
        items.isEmpty ? "(none)" : items.prefix(20).map { "- \($0)" }.joined(separator: "\n")
    }

    private static func fenced(_ text: String) -> String {
        "```diff\n\(text)\n```"
    }
}
