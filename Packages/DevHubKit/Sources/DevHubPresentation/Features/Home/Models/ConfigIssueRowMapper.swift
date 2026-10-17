import Foundation
import DevHubDomain
import DevHubUI

enum ConfigIssueRowMapper {
    static func model(for issue: ConfigIssue) -> ConfigIssueRowModel {
        ConfigIssueRowModel(id: issue.id, location: "\(issue.layer.rawValue): \(issue.fileName)", message: issue.message)
    }

    static func title(count: Int) -> String {
        count == 1 ? "1 config problem" : "\(count) config problems"
    }
}
