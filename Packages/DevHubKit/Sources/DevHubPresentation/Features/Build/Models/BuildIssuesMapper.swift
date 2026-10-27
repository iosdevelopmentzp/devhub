import Foundation
import DevHubDomain
import DevHubUI

enum BuildIssuesMapper {
    static func rows(for issues: [BuildIssue]) -> [BuildIssueRowModel] {
        let ordered = issues.filter { $0.severity == .error } + issues.filter { $0.severity == .warning }
        return ordered.enumerated().map { index, issue in
            let file = issue.path.map { ($0 as NSString).lastPathComponent }
            let location = file.map { name in issue.line.map { "\(name):\($0)" } ?? name }
            return BuildIssueRowModel(
                id: index,
                icon: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill",
                tint: issue.severity == .error ? .red : .orange,
                location: location,
                message: issue.message,
                path: issue.path,
                line: issue.line,
                hint: issue.path.map { path in "Open \(path)" + (issue.line.map { " at line \($0)" } ?? "") } ?? issue.message
            )
        }
    }

    static func title(for issues: [BuildIssue]) -> String {
        let errors = issues.filter { $0.severity == .error }.count
        let warnings = issues.count - errors
        return [
            errors > 0 ? CountText.count(errors, "error") : nil,
            warnings > 0 ? CountText.count(warnings, "warning") : nil,
        ].compactMap { $0 }.joined(separator: " · ")
    }
}
