import Foundation
import DevHubDomain
import DevHubUI

enum CommitFileRowMapper {

    static func model(for file: GitCommitFile, hash: String, isExpanded: Bool, diff: GitDiff?) -> CommitFileRowModel {
        CommitFileRowModel(
            id: CommitFileKey(hash: hash, path: file.path),
            letter: String(file.kind.letter),
            letterTint: FileChangeRowMapper.tint(file.kind),
            letterHint: FileChangeRowMapper.hint(file.kind),
            fileName: file.fileName,
            detail: file.originalPath.map { "\($0) →" } ?? file.folder,
            path: file.path,
            diff: isExpanded ? DiffMapper.model(for: diff) : nil
        )
    }
}
