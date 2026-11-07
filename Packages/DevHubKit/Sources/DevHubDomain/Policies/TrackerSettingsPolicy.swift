import Foundation

package enum TrackerSettingsPolicy {
    package static let defaultStatuses = ["To Do", "In Progress", "In Review", "Done"]
    package static let defaultStartStatus = "In Progress"
    package static let defaultBranchFormat = "feature/{key}-{slug}"

    package static func settings(for config: ProjectConfig) -> TrackerSettings {
        let tracker = config.tracker
        let statuses = (tracker?.statuses ?? []).compactMap(meaningful)
        return TrackerSettings(
            kind: tracker?.kind ?? detectKind(ticketURL: config.git?.ticketURL),
            project: meaningful(tracker?.project),
            statuses: statuses.isEmpty ? defaultStatuses : statuses,
            startStatus: meaningful(tracker?.startStatus) ?? defaultStartStatus,
            filter: meaningful(tracker?.filter),
            branchFormat: meaningful(tracker?.branchFormat) ?? defaultBranchFormat
        )
    }

    package static func detectKind(ticketURL: String?) -> TrackerKind {
        let lowered = ticketURL?.lowercased() ?? ""
        return lowered.contains("atlassian") || lowered.contains("jira") ? .jira : .disabled
    }

    private static func meaningful(_ value: String?) -> String? {
        guard let trimmed = value?.trimmed, trimmed.isEmpty == false else { return nil }
        return trimmed
    }
}
