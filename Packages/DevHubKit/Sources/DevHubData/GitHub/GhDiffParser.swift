import Foundation
import DevHubDomain

enum GhDiffParser {
    static let maxLines = 2_000

    private struct FileDTO: Decodable {
        let filename: String
        let previousFilename: String?
        let status: String
        let additions: Int
        let deletions: Int
        let changes: Int
        let patch: String?
    }

    static func files(from data: Data) throws -> [PullRequestFileDiff] {
        let files: [FileDTO] = try GhPullRequestParser.decodeREST(data)
        return files.map(file)
    }

    private static func file(_ dto: FileDTO) -> PullRequestFileDiff {
        let text = dto.patch ?? ""
        let lines = text.isEmpty ? [] : text.components(separatedBy: "\n")
        return PullRequestFileDiff(
            oldPath: dto.previousFilename ?? dto.filename,
            path: dto.filename,
            kind: kind(dto.status),
            additions: dto.additions,
            deletions: dto.deletions,
            diff: GitDiff(
                lines: Array(lines.prefix(maxLines)),
                droppedLines: max(lines.count - maxLines, 0),
                isBinary: dto.patch == nil && dto.changes == 0
            ),
            isTooLarge: dto.patch == nil && dto.changes > 0
        )
    }

    private static func kind(_ status: String) -> PullRequestFileDiff.Kind {
        switch status {
        case "added": .added
        case "removed": .deleted
        case "renamed": .renamed
        default: .modified
        }
    }
}
