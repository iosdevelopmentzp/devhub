import Foundation
import DevHubDomain

enum PullRequestExplainMapper {
    static func model(summary: PullRequestSummary, review: PullRequestReviewState, context: PullRequestRowContext) -> PullRequestExplainModel {
        let text = context.explanations[summary.id]
        let purpose = review.changedSinceReview.isEmpty
            ? "explains what this \(context.words.request) changes, the risky places and what to check"
            : "explains what this \(context.words.request) changes, the risky places, what changed since your review and what to check"
        return PullRequestExplainModel(
            button: AIWriteButtonMapper.model(
                title: text == nil ? "Explain" : "Explain Again",
                purpose: purpose,
                defaultProvider: context.aiProvider,
                isRunning: context.explainingIDs.contains(summary.id),
                isEnabled: true
            ),
            text: text.map(attributed)
        )
    }

    static func attributed(_ markdown: String) -> AttributedString {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#") else { return String(line) }
            return "**\(trimmed.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces))**"
        }
        return CommentText.attributed(lines.joined(separator: "\n"))
    }
}
