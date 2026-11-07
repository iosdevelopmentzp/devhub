import Foundation

package enum TrackerBranchPolicy {
    package static let maximumSlugLength = 40

    package static func branchName(for issue: TrackerIssue, format: String) -> String {
        let slug = slug(issue.summary)
        let name = format
            .replacingOccurrences(of: "{key}", with: issue.key)
            .replacingOccurrences(of: "{slug}", with: slug)
        var characters = Array(name)
        while let last = characters.last, last == "-" || last == "/" {
            characters.removeLast()
        }
        return String(characters)
    }

    package static func slug(_ text: String) -> String {
        var result = ""
        var pendingDash = false
        for scalar in text.lowercased().unicodeScalars {
            if scalar.isASCII, CharacterSet.alphanumerics.contains(scalar) {
                if pendingDash, result.isEmpty == false {
                    result.append("-")
                }
                result.unicodeScalars.append(scalar)
                pendingDash = false
            } else {
                pendingDash = true
            }
        }
        guard result.count > maximumSlugLength else { return result }
        let cut = String(result.prefix(maximumSlugLength))
        guard let dash = cut.lastIndex(of: "-") else { return cut }
        return String(cut[..<dash])
    }
}
