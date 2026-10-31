import Foundation
import DevHubDomain
import DevHubUI

enum QuickActionTileMapper {
    static func model(for action: CatalogAction, scheme: String?, branch: String?, words: CodeHostWords, isBuildRunning: Bool, isRunning: Bool) -> QuickActionTileModel {
        switch action {
        case let .builtin(builtin):
            let text = text(for: builtin, scheme: scheme, branch: branch, words: words)
            let isBuild = builtin == .buildRun || builtin == .runAttach || builtin == .build
            return QuickActionTileModel(
                id: action.id,
                title: text.title,
                subtitle: text.subtitle,
                systemImage: systemImage(for: builtin),
                tint: tint(for: builtin),
                isRunning: isBuild && isBuildRunning,
                isEnabled: isBuild ? isBuildRunning == false : builtin != .copyBranch || branch != nil
            )
        case let .config(resolved):
            return QuickActionTileModel(
                id: action.id,
                title: resolved.config.title,
                subtitle: resolved.config.subtitle ?? "",
                systemImage: resolved.config.icon ?? ConfigActionItemMapper.defaultSymbol,
                tint: ConfigTintMapper.tint(resolved.config.tint),
                isRunning: isRunning,
                isEnabled: resolved.origin.isExecutable && isRunning == false
            )
        }
    }

    static func systemImage(for builtin: BuiltinAction) -> String {
        switch builtin {
        case .buildRun: "play.fill"
        case .runAttach: "ladybug.fill"
        case .build: "hammer.circle.fill"
        case .openEditor: "hammer.fill"
        case .openFolder: "folder.fill"
        case .terminal: "terminal.fill"
        case .copyBranch: "doc.on.doc.fill"
        case .repository: "globe"
        case .newPullRequest: "arrow.triangle.pull"
        case .pullRequests: "arrow.triangle.merge"
        }
    }

    static func tint(for builtin: BuiltinAction) -> Tint {
        switch builtin {
        case .buildRun: .green
        case .runAttach: .orange
        case .build: .teal
        case .openEditor: .indigo
        case .openFolder: .blue
        case .terminal: .gray
        case .copyBranch: .teal
        case .repository: .purple
        case .newPullRequest: .pink
        case .pullRequests: .blue
        }
    }

    private static func text(for builtin: BuiltinAction, scheme: String?, branch: String?, words: CodeHostWords) -> (title: String, subtitle: String) {
        switch builtin {
        case .buildRun: ("Build & Run", scheme.map { "Scheme \($0)" } ?? "Target simulator, run bar options")
        case .runAttach: ("Run & Attach", "Build, launch, attach Xcode")
        case .build: ("Build", scheme.map { "Scheme \($0), no launch" } ?? "Compile only, no launch")
        case .openEditor: ("Open in Xcode", "Main checkout")
        case .openFolder: ("Open folder", "Reveal in Finder")
        case .terminal: ("Terminal here", "Main checkout")
        case .copyBranch: ("Copy branch", branch ?? "No branch")
        case .repository: ("Repository", "Open the web page")
        case .newPullRequest: (words.requestSentence, "New request for this branch")
        case .pullRequests: (words.requestsTitle, "Open the tab")
        }
    }
}
