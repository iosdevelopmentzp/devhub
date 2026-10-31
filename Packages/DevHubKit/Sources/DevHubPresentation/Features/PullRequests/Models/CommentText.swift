import Foundation

enum CommentText {
    static func attributed(_ text: String) -> AttributedString {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: trimmed, options: options)) ?? AttributedString(trimmed)
    }

    static func firstLine(_ text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        return firstLine.trimmingCharacters(in: .whitespaces)
    }
}
