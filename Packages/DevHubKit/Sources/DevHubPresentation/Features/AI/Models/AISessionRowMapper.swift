import Foundation
import DevHubDomain
import DevHubUI

enum AISessionRowMapper {

    static func model(for item: AISession) -> AISessionRowModel {
        let name = title(for: item.provider)
        return AISessionRowModel(
            id: item.id,
            title: item.title,
            icon: icon(for: item.provider),
            iconTint: item.folderExists ? .orange : .secondary,
            providerTag: TagModel(name, tint: .secondary),
            dateText: item.updatedAt.formatted(date: .abbreviated, time: .shortened),
            folderPath: item.cwd,
            folderDisplayPath: item.cwd.abbreviatingHome,
            branchTag: item.gitBranch.map { TagModel($0, tint: .blue, systemImage: "arrow.triangle.branch") },
            statusTags: item.folderExists ? [] : [TagModel("folder missing", tint: .red, systemImage: "folder.badge.questionmark")],
            lastPrompt: item.lastPrompt.flatMap { $0 == item.title ? nil : $0 },
            resumeCommand: item.resumeCommand,
            terminalCommand: item.terminalCommand,
            terminalTitle: "Resumed \(name) session",
            canResume: item.folderExists,
            resumeHint: item.folderExists
                ? "Open the terminal in \(item.folderName) and run \(item.provider.executable) --resume"
                : "The folder of this session no longer exists",
            canShowFolder: item.folderExists
        )
    }

    static func title(for provider: AIProvider) -> String {
        switch provider {
        case .copilot: "Copilot"
        case .claude: "Claude"
        }
    }

    private static func icon(for provider: AIProvider) -> String {
        switch provider {
        case .copilot: "chevron.left.forwardslash.chevron.right"
        case .claude: "sparkles"
        }
    }
}
