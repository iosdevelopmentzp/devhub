import Foundation
import DevHubDomain

actor CopilotSessionRepository: AISessionRepository {
    private struct CacheEntry {
        let modified: Date
        let session: AISession?
    }

    private let root: URL
    private var cache: [String: CacheEntry] = [:]

    init(root: URL) {
        self.root = root
    }

    func sessions() async -> [AISession] {
        var result: [AISession] = []
        var seen = Set<String>()
        for (folder, modified) in Self.sessionFolders(in: root) {
            let path = folder.path
            seen.insert(path)
            let session: AISession?
            if let entry = cache[path], entry.modified == modified {
                session = entry.session
            } else {
                session = Self.session(folder: folder, modified: modified)
                cache[path] = CacheEntry(modified: modified, session: session)
            }
            guard var session else { continue }
            session.folderExists = FileManager.default.fileExists(atPath: session.cwd)
            result.append(session)
        }
        cache = cache.filter { seen.contains($0.key) }
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    nonisolated private static func sessionFolders(in root: URL) -> [(URL, Date)] {
        let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        return folders.compactMap { folder in
            guard isSafe(folder.lastPathComponent), let events = modified(folder.appendingPathComponent("events.jsonl")) else { return nil }
            let workspace = modified(folder.appendingPathComponent("workspace.yaml")) ?? events
            return (folder, max(events, workspace))
        }
    }

    nonisolated private static func session(folder: URL, modified: Date) -> AISession? {
        guard let workspace = try? String(contentsOf: folder.appendingPathComponent("workspace.yaml"), encoding: .utf8) else { return nil }
        let events = (try? Data(contentsOf: folder.appendingPathComponent("events.jsonl"), options: .mappedIfSafe)) ?? Data()
        return CopilotSessionParser.parse(id: folder.lastPathComponent, workspace: workspace, events: events, modified: modified)
    }

    nonisolated private static func modified(_ url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    nonisolated private static func isSafe(_ id: String) -> Bool {
        id.isEmpty == false && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}
