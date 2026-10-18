import Foundation
import DevHubDomain
import DevHubUI

enum AISessionRowMapper {

    static func model(for item: AISession) -> AISessionRowModel {
        AISessionRowModel(
            id: item.id,
            title: item.title,
            icon: "sparkles",
            iconTint: item.folderExists ? .orange : .secondary,
            dateText: item.updatedAt.formatted(date: .abbreviated, time: .shortened),
            folderPath: item.cwd,
            folderDisplayPath: item.cwd.abbreviatingHome,
            branchTag: item.gitBranch.map { TagModel($0, tint: .blue, systemImage: "arrow.triangle.branch") },
            statusTags: item.folderExists ? [] : [TagModel("folder missing", tint: .red, systemImage: "folder.badge.questionmark")],
            lastPrompt: item.lastPrompt.flatMap { $0 == item.title ? nil : $0 },
            resumeCommand: item.resumeCommand,
            terminalCommand: "claude --resume \(item.id)",
            canResume: item.folderExists,
            resumeHint: item.folderExists
                ? "Open the terminal in \(item.folderName) and run claude --resume"
                : "The folder of this session no longer exists",
            canShowFolder: item.folderExists
        )
    }
}
