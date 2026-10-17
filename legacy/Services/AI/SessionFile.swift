import Foundation

nonisolated struct SessionFile: Sendable {
    enum Kind: Sendable {
        case copilot(id: String)
        case claude(id: String)
    }

    let path: String
    let modified: Date
    let kind: Kind

    func parse() -> AISession? {
        switch kind {
        case .copilot(let id): parseCopilot(id: id)
        case .claude(let id): parseClaude(id: id)
        }
    }

    private func parseCopilot(id: String) -> AISession? {
        guard Self.isSafe(id) else { return nil }
        guard let yaml = try? String(contentsOfFile: path + "/workspace.yaml", encoding: .utf8) else { return nil }
        let values = WorkspaceYAMLParser.parse(yaml)
        guard let cwd = values["cwd"], cwd.isEmpty == false else { return nil }
        let events = (try? Data(contentsOf: URL(fileURLWithPath: path + "/events.jsonl"), options: .alwaysMapped)) ?? Data()
        let prompts = CopilotEventScanner.scan(events)
        let folderName = URL(fileURLWithPath: cwd).lastPathComponent
        let title = SessionText.nonEmpty(values["name"]) ?? SessionText.nonEmpty(values["summary"]) ?? prompts.first ?? folderName
        return AISession(
            id: id,
            provider: .copilot,
            title: title,
            date: ISODateParser.parse(values["updated_at"]) ?? modified,
            folder: (cwd as NSString).abbreviatingWithTildeInPath,
            branch: SessionText.nonEmpty(values["branch"]),
            lastPrompt: prompts.last ?? "",
            cwd: cwd,
            folderExists: FileManager.default.fileExists(atPath: cwd)
        )
    }

    private func parseClaude(id: String) -> AISession? {
        guard Self.isSafe(id) else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped) else { return nil }
        let facts = ClaudeSessionScanner.scan(data)
        guard let cwd = facts.cwd else { return nil }
        return AISession(
            id: id,
            provider: .claude,
            title: facts.title ?? URL(fileURLWithPath: cwd).lastPathComponent,
            date: modified,
            folder: (cwd as NSString).abbreviatingWithTildeInPath,
            branch: facts.branch,
            lastPrompt: facts.lastPrompt ?? "",
            cwd: cwd,
            folderExists: FileManager.default.fileExists(atPath: cwd)
        )
    }

    private static func isSafe(_ id: String) -> Bool {
        id.isEmpty == false && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}
