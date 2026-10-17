import Foundation

nonisolated struct ClaudeSessionFacts: Sendable {
    var customTitle: String?
    var aiTitle: String?
    var lastPrompt: String?
    var cwd: String?
    var branch: String?
    var startedAt: Date?

    var title: String? { customTitle ?? aiTitle ?? lastPrompt }
}

nonisolated enum ClaudeSessionScanner {
    static func scan(_ data: Data) -> ClaudeSessionFacts {
        var facts = ClaudeSessionFacts()
        LineScanner.forEachLine(in: data) { line in
            if LineScanner.hasPrefix(line, "{\"type\":\"custom-title\"") {
                facts.customTitle = text(line, key: "customTitle") ?? facts.customTitle
            } else if LineScanner.hasPrefix(line, "{\"type\":\"ai-title\"") {
                facts.aiTitle = text(line, key: "aiTitle") ?? facts.aiTitle
            } else if LineScanner.hasPrefix(line, "{\"type\":\"last-prompt\"") {
                facts.lastPrompt = text(line, key: "lastPrompt") ?? facts.lastPrompt
            } else if facts.cwd == nil, LineScanner.contains(line, "\"cwd\":\"") {
                readContext(line, into: &facts)
            }
            return true
        }
        return facts
    }

    private static func text(_ line: UnsafeRawBufferPointer, key: String) -> String? {
        SessionText.nonEmpty(LineScanner.object(line)?[key] as? String)
    }

    private static func readContext(_ line: UnsafeRawBufferPointer, into facts: inout ClaudeSessionFacts) {
        guard let object = LineScanner.object(line), let cwd = object["cwd"] as? String, cwd.isEmpty == false else { return }
        facts.cwd = cwd
        if let branch = object["gitBranch"] as? String, branch.isEmpty == false {
            facts.branch = branch
        }
        facts.startedAt = ISODateParser.parse(object["timestamp"] as? String)
    }
}
