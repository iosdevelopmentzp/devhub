import Foundation
import DevHubDomain

enum ClaudeTranscriptParser {
    static func parse(lines: [String], url: URL, modified: Date) -> ClaudeSession? {
        let id = url.deletingPathExtension().lastPathComponent
        var customTitle: String?
        var aiTitle: String?
        var lastPrompt: String?
        var cwd: String?
        var gitBranch: String?
        var startedAt: Date?
        for line in lines where line.isEmpty == false {
            let head = String(line.prefix(40))
            if head.hasPrefix(#"{"type":"custom-title""#) {
                customTitle = string(in: line, key: "customTitle") ?? customTitle
            } else if head.hasPrefix(#"{"type":"ai-title""#) {
                aiTitle = string(in: line, key: "aiTitle") ?? aiTitle
            } else if head.hasPrefix(#"{"type":"last-prompt""#) {
                lastPrompt = string(in: line, key: "lastPrompt") ?? lastPrompt
            } else if cwd == nil, head.hasPrefix(#"{"type":"#) == false || head.hasPrefix(#"{"type":"user""#) || head.hasPrefix(#"{"type":"attachment""#) {
                guard let object = object(in: line), let value = object["cwd"] as? String else { continue }
                cwd = value
                gitBranch = (object["gitBranch"] as? String).flatMap { $0.isEmpty || $0 == "HEAD" ? nil : $0 }
                startedAt = (object["timestamp"] as? String).flatMap { ISO8601.date(from: $0) }
            }
        }
        guard let cwd else { return nil }
        let prompt = lastPrompt.map(singleLine)
        guard let title = customTitle ?? aiTitle ?? prompt, title.isEmpty == false else { return nil }
        return ClaudeSession(
            id: id,
            title: singleLine(title),
            lastPrompt: prompt,
            cwd: cwd,
            gitBranch: gitBranch,
            startedAt: startedAt,
            updatedAt: modified,
            folderExists: false
        )
    }

    private static func object(in line: String) -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
    }

    private static func string(in line: String, key: String) -> String? {
        object(in: line)?[key] as? String
    }

    private static func singleLine(_ text: String) -> String {
        let collapsed = text.split(whereSeparator: \.isNewline).joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return collapsed.count > 300 ? String(collapsed.prefix(300)) + "…" : collapsed
    }
}
