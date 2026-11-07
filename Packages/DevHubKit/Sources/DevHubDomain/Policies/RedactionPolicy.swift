import Foundation

package enum RedactionPolicy {
    package static let redacted = "<redacted>"

    package static let secret = "<secret>"
    package static let url = "<url>"
    package static let email = "<email>"
    package static let ip = "<ip>"

    private static let secretPatterns = [
        #"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}"#,
        #"\bgithub_pat_[A-Za-z0-9_]{20,}"#,
        #"\bglpat-[A-Za-z0-9_\-]{20,}"#,
        #"(?<![A-Fa-f0-9])[a-f0-9]{40}(?![A-Fa-f0-9])"#,
    ]
    private static let emailPattern = #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#
    private static let urlPattern = #"[A-Za-z][A-Za-z0-9+.\-]*://[^\s"'<>()\[\]]*[^\s"'<>()\[\].,;:!?]"#
    private static let ipPattern = #"(?<![0-9.])(?:25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])(?:\.(?:25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])){3}(?![0-9.])"#

    package static func redact(_ text: String, subjects: RedactionSubjects, words: [RedactionWord]) -> String {
        var result = text
        for pattern in secretPatterns {
            result = replace(pattern: pattern, caseInsensitive: false, with: secret, in: result)
        }
        result = replace(pattern: urlPattern, caseInsensitive: false, with: url, in: result)
        result = replace(pattern: emailPattern, caseInsensitive: false, with: email, in: result)
        result = replace(pattern: ipPattern, caseInsensitive: false, with: ip, in: result)
        if let folder = subjects.projectFolder, folder.isEmpty == false {
            result = result.replacingOccurrences(of: folder, with: "<project>")
        }
        if let home = subjects.homeFolder, home.isEmpty == false {
            result = result.replacingOccurrences(of: home, with: "~")
        }
        if let user = subjects.userName {
            result = replaceWord(user, with: "<user>", in: result)
        }
        for (_, bundle) in ranked(subjects.bundleIDs) {
            result = replaceWord(bundle, with: "<bundle>", in: result)
        }
        for (_, scheme) in ranked(subjects.schemes) {
            result = replaceWord(scheme, with: "<scheme>", in: result)
        }
        for (_, name) in ranked(subjects.projectNames) {
            result = replaceWord(name, with: "<project>", in: result)
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
