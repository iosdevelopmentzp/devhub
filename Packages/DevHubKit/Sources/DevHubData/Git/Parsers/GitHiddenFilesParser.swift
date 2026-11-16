import Foundation
import DevHubDomain

enum GitHiddenFilesParser {
    struct Entry: Equatable {
        let path: String
        let flags: Set<GitHiddenFlag>
        let objectID: String
    }

    static func entries(_ output: String) -> [Entry] {
        output.split(separator: "\0").compactMap { record in
            entry(String(record))
        }
    }

    static func flags(forTag tag: Character) -> Set<GitHiddenFlag> {
        var flags: Set<GitHiddenFlag> = []
        if tag == "S" || tag == "s" {
            flags.insert(.skipWorktree)
        }
        if tag.isLowercase {
            flags.insert(.assumeUnchanged)
        }
        return flags
    }

    private static func entry(_ record: String) -> Entry? {
        guard let tab = record.firstIndex(of: "\t") else { return nil }
        let fields = record[..<tab].split(separator: " ")
        guard fields.count == 4, fields[3] == "0", let tag = fields[0].first else { return nil }
        let flags = flags(forTag: tag)
        guard flags.isEmpty == false else { return nil }
        return Entry(path: String(record[record.index(after: tab)...]), flags: flags, objectID: String(fields[2]))
    }
}
