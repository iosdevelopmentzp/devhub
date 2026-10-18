import Foundation
import DevHubDomain

actor ClaudeTranscriptSessionRepository: AISessionRepository {
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
        let files = Self.transcriptFiles(in: root)
        var result: [AISession] = []
        var seen = Set<String>()
        for (url, modified) in files {
            let path = url.path
            seen.insert(path)
            if let entry = cache[path], entry.modified == modified {
                if var session = entry.session {
                    session.folderExists = FileManager.default.fileExists(atPath: session.cwd)
                    result.append(session)
                }
                continue
            }
            let session = Self.session(url: url, modified: modified)
            cache[path] = CacheEntry(modified: modified, session: session)
            if let session {
                result.append(session)
            }
        }
        cache = cache.filter { seen.contains($0.key) }
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    nonisolated private static func transcriptFiles(in root: URL) -> [(URL, Date)] {
        let manager = FileManager.default
        guard let folders = try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else { return [] }
        return folders.flatMap { folder -> [(URL, Date)] in
            let files = (try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
            return files.compactMap { file in
                guard file.pathExtension == "jsonl", UUID(uuidString: file.deletingPathExtension().lastPathComponent) != nil else { return nil }
                let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return (file, modified)
            }
        }
    }

    nonisolated private static func session(url: URL, modified: Date) -> AISession? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        let lines = data.split(separator: 0x0A, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
        guard var session = ClaudeTranscriptParser.parse(lines: lines, url: url, modified: modified) else { return nil }
        session.folderExists = FileManager.default.fileExists(atPath: session.cwd)
        return session
    }
}
