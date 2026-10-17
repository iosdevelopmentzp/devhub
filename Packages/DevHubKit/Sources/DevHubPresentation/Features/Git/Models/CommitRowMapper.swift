import Foundation
import DevHubDomain
import DevHubUI

enum CommitRowMapper {

    struct Expansion {
        let files: [GitCommitFile]?
        let error: String?
        let expandedFiles: Set<CommitFileKey>
        let diffs: [CommitFileKey: GitDiff]
    }

    static func model(for commit: GitCommit, webBase: URL?, expansion: Expansion?) -> CommitRowModel {
        CommitRowModel(
            id: commit.id,
            hash: commit.hash,
            shortHash: commit.shortHash,
            subject: commit.subject,
            refTags: CommitRefTagMapper.tags(for: commit.refs),
            tags: tags(for: commit),
            author: commit.author,
            dateText: commit.date?.relativeDescription,
            webURL: commit.isPushed ? webBase.flatMap { RepositoryWebLinks.commitURL(base: $0, hash: commit.hash) } : nil,
            files: expansion.map { files(for: commit.hash, $0) }
        )
    }

    private static func tags(for commit: GitCommit) -> [TagModel] {
        var tags: [TagModel] = []
        if commit.isMerge {
            tags.append(TagModel("merge", tint: .gray, systemImage: "arrow.triangle.merge", hint: "A merge commit. Its files are the changes against the first parent."))
        }
        if commit.isPushed == false {
            tags.append(TagModel("not pushed", tint: .orange))
        }
        return tags
    }

    static func files(for hash: String, _ expansion: Expansion) -> CommitRowModel.Files {
        if let error = expansion.error {
            return .note("Cannot read the files: \(error)")
        }
        guard let files = expansion.files else { return .loading }
        guard files.isEmpty == false else { return .note("No file changes in this commit") }
        return .loaded(files.map { file in
            let key = CommitFileKey(hash: hash, path: file.path)
            let isExpanded = expansion.expandedFiles.contains(key)
            return CommitFileRowMapper.model(for: file, hash: hash, isExpanded: isExpanded, diff: expansion.diffs[key])
        })
    }
}
