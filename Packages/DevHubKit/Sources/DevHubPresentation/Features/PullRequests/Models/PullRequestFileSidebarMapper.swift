import Foundation
import DevHubUI

enum PullRequestFileSidebarMapper {

    static func model(for loaded: PullRequestDetailsModel.Loaded, query: String) -> PullRequestFileSidebarModel {
        let files = loaded.files
        let viewed = files.filter(\.isViewed).count
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = needle.isEmpty ? files : files.filter { $0.path.localizedCaseInsensitiveContains(needle) }
        return PullRequestFileSidebarModel(
            title: "Files \(files.count)",
            progressText: "\(viewed) of \(files.count) viewed",
            progress: files.isEmpty ? 0 : Double(viewed) / Double(files.count),
            groups: loaded.fileGroups,
            rows: shown.map(row),
            emptyText: emptyText(files: files, shown: shown, needle: needle)
        )
    }

    static func row(_ file: PullRequestFileRowModel) -> PullRequestFileSidebarRowModel {
        PullRequestFileSidebarRowModel(
            id: file.id,
            letter: file.letter,
            letterTint: file.letterTint,
            fileName: file.fileName,
            folder: file.detail,
            path: file.path,
            additionsText: file.additionsText,
            deletionsText: file.deletionsText,
            isViewed: file.isViewed,
            isExpanded: file.isExpanded,
            isChanged: file.reviewTag != nil,
            threadCountText: file.threadCountText,
            hint: "\(file.path). Click to show its diff."
        )
    }

    private static func emptyText(files: [PullRequestFileRowModel], shown: [PullRequestFileRowModel], needle: String) -> String? {
        guard shown.isEmpty else { return nil }
        return files.isEmpty ? "No files" : "No file matches “\(needle)”"
    }
}
