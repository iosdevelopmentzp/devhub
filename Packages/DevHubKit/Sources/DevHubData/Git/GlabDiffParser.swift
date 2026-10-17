import Foundation
import DevHubDomain

enum GlabDiffParser {
    static let maxLines = 2_000

    private struct FileDTO: Decodable {
        let oldPath: String
        let newPath: String
        let newFile: Bool?
        let deletedFile: Bool?
        let renamedFile: Bool?
        let tooLarge: Bool?
        let diff: String?
    }

    static func files(from data: Data) throws -> [PullRequestFileDiff] {
        let files: [FileDTO] = try GlabPullRequestParser.decode(data)
        return files.map(file)
    }

    private static func file(_ dto: FileDTO) -> PullRequestFileDiff {
        let text = dto.diff ?? ""
        let lines = text.isEmpty ? [] : text.components(separatedBy: "\n").dropLastIfEmpty()
        return PullRequestFileDiff(
            oldPath: dto.oldPath,
            path: dto.newPath,
            kind: kind(dto),
            additions: lines.count { $0.hasPrefix("+") },
            deletions: lines.count { $0.hasPrefix("-") },
            diff: GitDiff(
                lines: Array(lines.prefix(maxLines)),
                droppedLines: max(lines.count - maxLines, 0),
                isBinary: text.hasPrefix("Binary files")
            ),
            isTooLarge: dto.tooLarge ?? false
        )
    }

    private static func kind(_ dto: FileDTO) -> PullRequestFileDiff.Kind {
        if dto.newFile == true { return .added }
        if dto.deletedFile == true { return .deleted }
        if dto.renamedFile == true { return .renamed }
        return .modified
    }
}

private extension Array where Element == String {
    func dropLastIfEmpty() -> [String] {
        last?.isEmpty == true ? Array(dropLast()) : self
    }
}
