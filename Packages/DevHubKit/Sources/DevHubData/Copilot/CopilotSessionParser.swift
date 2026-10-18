import Foundation
import DevHubDomain

enum CopilotSessionParser {
    static func parse(id: String, workspace: String, events: Data, modified: Date) -> AISession? {
        let values = WorkspaceYAMLParser.parse(workspace)
        guard let cwd = nonEmpty(values["cwd"]) else { return nil }
        let prompts = CopilotEventScanner.scan(events)
        let title = nonEmpty(values["name"]) ?? nonEmpty(values["summary"]) ?? prompts.first ?? (cwd as NSString).lastPathComponent
        return AISession(
            id: id,
            provider: .copilot,
            title: title,
            lastPrompt: prompts.last,
            cwd: cwd,
            gitBranch: nonEmpty(values["branch"]).flatMap { $0 == "HEAD" ? nil : $0 },
            startedAt: values["created_at"].flatMap(ISO8601.date(from:)),
            updatedAt: values["updated_at"].flatMap(ISO8601.date(from:)) ?? modified,
            folderExists: false
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmed, value.isEmpty == false else { return nil }
        return value
    }
}
