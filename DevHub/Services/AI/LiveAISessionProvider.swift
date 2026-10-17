import Foundation

nonisolated struct LiveAISessionProvider: AISessionProviding {
    let index: AISessionIndex

    init(home: String) {
        index = AISessionIndex(home: home)
    }

    func sessions() async throws -> [AISession] {
        await index.load()
    }
}

actor AISessionIndex {
    private struct Entry {
        let modified: Date
        let session: AISession?
    }

    private let home: String
    private var cache: [String: Entry] = [:]

    init(home: String) {
        self.home = home
    }

    func load() async -> [AISession] {
        let candidates = copilotCandidates() + claudeCandidates()
        let stale = candidates.filter { cache[$0.path]?.modified != $0.modified }
        let parsed = await withTaskGroup(of: (String, Entry).self) { group in
            for candidate in stale {
                group.addTask { (candidate.path, Entry(modified: candidate.modified, session: candidate.parse())) }
            }
            var results: [(String, Entry)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        for (path, entry) in parsed {
            cache[path] = entry
        }
        let live = Set(candidates.map(\.path))
        cache = cache.filter { live.contains($0.key) }
        return candidates.compactMap { candidate in
            guard var session = cache[candidate.path]?.session else { return nil }
            session.folderExists = FileManager.default.fileExists(atPath: session.cwd)
            return session
        }
    }

    private func copilotCandidates() -> [SessionFile] {
        let root = home + "/.copilot/session-state"
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root)) ?? []
        return names.compactMap { name in
            let folder = root + "/" + name
            guard let events = Self.modified(folder + "/events.jsonl") else { return nil }
            let workspace = Self.modified(folder + "/workspace.yaml") ?? events
            return SessionFile(path: folder, modified: max(events, workspace), kind: .copilot(id: name))
        }
    }

    private func claudeCandidates() -> [SessionFile] {
        let root = home + "/.claude/projects"
        let projects = (try? FileManager.default.contentsOfDirectory(atPath: root)) ?? []
        return projects.flatMap { project -> [SessionFile] in
            let folder = root + "/" + project
            let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
            return names.compactMap { name in
                guard name.hasSuffix(".jsonl") else { return nil }
                let path = folder + "/" + name
                guard let modified = Self.modified(path) else { return nil }
                return SessionFile(path: path, modified: modified, kind: .claude(id: String(name.dropLast(6))))
            }
        }
    }

    private static func modified(_ path: String) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }
}
