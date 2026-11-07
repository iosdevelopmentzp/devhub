import Foundation

package enum CIRedactionPolicy {
    package static let redacted = "<redacted>"

    package static func redact(_ text: String, subjects: CIRedactionSubjects, words: [RedactionWord]) -> String {
        var result = text
        if let home = subjects.homeFolder, home.isEmpty == false {
            result = result.replacingOccurrences(of: home, with: "~")
        }
        for (offset, branch) in ranked(subjects.branches) {
            result = replaceWord(branch, with: "<branch-\(offset + 1)>", in: result)
        }
        for (offset, login) in ranked(subjects.logins) {
            result = replaceWord(login, with: "<user-\(offset + 1)>", in: result)
        }
        if let host = subjects.host {
            result = replaceWord(host, with: "<host>", in: result)
        }
        if let organization = subjects.organization {
            result = replaceWord(organization, with: "<org>", in: result)
        }
        if let repository = subjects.repository {
            result = replaceWord(repository, with: "<repo>", in: result)
        }
        for word in words {
            switch word {
            case .word(let value):
                result = replaceWord(value, with: redacted, in: result)
            case .pattern(let pattern):
                result = replace(pattern: pattern, caseInsensitive: true, with: redacted, in: result)
            }
        }
        return result
    }

    private static func ranked(_ values: [String]) -> [(offset: Int, value: String)] {
        values.enumerated()
            .filter { $0.element.isEmpty == false }
            .map { (offset: $0.offset, value: $0.element) }
            .sorted { $0.value.count > $1.value.count }
    }

    private static func replaceWord(_ word: String, with replacement: String, in text: String) -> String {
        guard word.isEmpty == false else { return text }
        let pattern = "(?<![A-Za-z0-9_])" + NSRegularExpression.escapedPattern(for: word) + "(?![A-Za-z0-9_])"
        return replace(pattern: pattern, caseInsensitive: true, with: replacement, in: text)
    }

    private static func replace(pattern: String, caseInsensitive: Bool, with replacement: String, in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : []) else { return text }
        let template = NSRegularExpression.escapedTemplate(for: replacement)
        return regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
    }
}
