import Foundation
import DevHubDomain

struct FileMockSetRepository: MockSetRepository {
    let root: URL

    func list(in location: MockSetLocation) async throws -> [MockSet] {
        try entries(in: folder(for: location)).map(\.set).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func save(_ set: MockSet, in location: MockSetLocation) async throws {
        let folder = folder(for: location)
        let existing = try entries(in: folder)
        let takenStems = Set(existing.filter { $0.set.id != set.id }.map(\.stem))
        var stem = MockRouteName.stem(for: set.name)
        var counter = 2
        let base = stem
        while takenStems.contains(stem) {
            stem = "\(base)-\(counter)"
            counter += 1
        }
        let encoded = try MockSetFileCoder.encode(set, bodyFolder: "\(stem)/bodies")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for old in existing where old.set.id == set.id {
                try removeFiles(stem: old.stem, in: folder)
            }
            try? FileManager.default.removeItem(at: folder.appendingPathComponent(stem, isDirectory: true))
            for (path, data) in encoded.bodies {
                let url = folder.appendingPathComponent(path)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            }
            try encoded.json.write(to: folder.appendingPathComponent("\(stem).json"), options: .atomic)
        } catch {
            throw MockSetError.writeFailed(error.localizedDescription)
        }
    }

    func delete(id: MockSet.ID, in location: MockSetLocation) async throws {
        let folder = folder(for: location)
        do {
            for entry in try entries(in: folder) where entry.set.id == id {
                try removeFiles(stem: entry.stem, in: folder)
            }
        } catch let error as MockSetError {
            throw error
        } catch {
            throw MockSetError.writeFailed(error.localizedDescription)
        }
    }

    func folder(for location: MockSetLocation) -> URL {
        switch location {
        case .defaultFolder(let project):
            root.appendingPathComponent(MockRouteName.stem(for: project), isDirectory: true)
        case .folder(let path):
            URL(fileURLWithPath: path, isDirectory: true)
        }
    }

    private func entries(in folder: URL) throws -> [(stem: String, set: MockSet)] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return try names.filter { $0.hasSuffix(".json") }.sorted().map { name in
            let url = folder.appendingPathComponent(name)
            guard let data = FileManager.default.contents(atPath: url.path) else {
                throw MockSetError.unreadable(file: name, reason: "The file cannot be opened.")
            }
            let set = try MockSetFileCoder.decode(data, file: name) { relative in
                FileManager.default.contents(atPath: folder.appendingPathComponent(relative).path)
            }
            return ((name as NSString).deletingPathExtension, set)
        }
    }

    private func removeFiles(stem: String, in folder: URL) throws {
        try FileManager.default.removeItem(at: folder.appendingPathComponent("\(stem).json"))
        let bodies = folder.appendingPathComponent(stem, isDirectory: true)
        if FileManager.default.fileExists(atPath: bodies.path) {
            try FileManager.default.removeItem(at: bodies)
        }
    }
}
