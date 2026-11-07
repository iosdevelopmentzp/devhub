import Foundation
import DevHubDomain
import DevHubUI

enum PaletteMapper {
    static let limit = 60

    static func items(from sources: PaletteSources, actionTitle: (CatalogAction) -> String) -> [PaletteItem] {
        tabItems(sources) + projectItems(sources) + actionItems(sources, title: actionTitle) + simulatorItems(sources) + branchItems(sources)
            + worktreeItems(sources) + pullRequestItems(sources) + sessionItems(sources) + newSessionItems(sources) + [keepAwakeItem(sources), settingsItem]
    }

    static func matches(_ items: [PaletteItem], query: String) -> [PaletteItem] {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard words.isEmpty == false else { return Array(items.prefix(limit)) }
        let found = items.enumerated().compactMap { index, item -> (rank: Int, index: Int, item: PaletteItem)? in
            let title = item.title.lowercased()
            let text = "\(title) \(item.subtitle.lowercased()) \(item.section.lowercased())"
            guard words.allSatisfy(text.contains) else { return nil }
            let rank = title.hasPrefix(words[0]) ? 0 : title.contains(words[0]) ? 1 : 2
            return (rank, index, item)
        }
        return found.sorted { ($0.rank, $0.index) < ($1.rank, $1.index) }.prefix(limit).map(\.item)
    }

    private static let settingsItem = PaletteItem(id: "settings", title: "Settings", subtitle: "Open the settings of DevHub", systemImage: "gearshape", section: "Tabs", command: .openSettings)

    private static func keepAwakeItem(_ sources: PaletteSources) -> PaletteItem {
        let card = KeepAwakeCardMapper.model(isActive: sources.isKeepAwakeOn)
        return PaletteItem(
            id: "keepAwake",
            title: sources.isKeepAwakeOn ? "Let the Mac sleep" : "Keep Mac awake",
            subtitle: card.subtitle,
            systemImage: card.systemImage,
            section: "Actions",
            command: .toggleKeepAwake
        )
    }

    private static func projectItems(_ sources: PaletteSources) -> [PaletteItem] {
        ProjectSwitchMapper.items(projects: sources.projects, selectedID: sources.selectedProjectID)
            .filter { $0.isSelected == false }
            .compactMap { item in
                guard let project = sources.projects.first(where: { $0.id == item.id }) else { return nil }
                return PaletteItem(
                    id: "project:\(item.id)",
                    title: "Switch to project \(item.title)",
                    subtitle: [item.shortcutText, project.path.abbreviatingHome].compactMap { $0 }.joined(separator: " · "),
                    systemImage: "shippingbox",
                    section: "Projects",
                    command: .selectProject(item.id)
                )
            }
    }

    private static func tabItems(_ sources: PaletteSources) -> [PaletteItem] {
        sources.tabs.map { tab in
            PaletteItem(id: "tab:\(tab.id.rawValue)", title: tab.title, subtitle: "Show the tab", systemImage: tab.systemImage, section: "Tabs", command: .showTab(tab.id))
        }
    }

    private static func actionItems(_ sources: PaletteSources, title: (CatalogAction) -> String) -> [PaletteItem] {
        sources.actions.map { action in
            PaletteItem(
                id: "action:\(action.id)",
                title: title(action),
                subtitle: action.resolved.map { $0.config.subtitle ?? $0.origin.fileName } ?? "Built-in action",
                systemImage: action.resolved?.config.icon ?? "bolt",
                section: "Actions",
                command: .runAction(action)
            )
        }
    }

    private static func simulatorItems(_ sources: PaletteSources) -> [PaletteItem] {
        sources.simulators.flatMap { simulator -> [PaletteItem] in
            let state = simulator.isPhysical ? (simulator.state == .booted ? "connected device" : "device, not connected") : (simulator.state == .booted ? "booted" : "shut down")
            var items = [
                PaletteItem(id: "run:\(simulator.id)", title: "Build & Run on \(simulator.name)", subtitle: state, systemImage: "play.fill", section: "Simulators", command: .buildAndRun(on: simulator.id))
            ]
            if simulator.id != sources.targetID {
                items.append(PaletteItem(id: "target:\(simulator.id)", title: "Make \(simulator.name) the target", subtitle: state, systemImage: "scope", section: "Simulators", command: .selectTarget(simulator.id)))
            }
            return items
        }
    }

    private static func branchItems(_ sources: PaletteSources) -> [PaletteItem] {
        sources.branches.filter { $0 != sources.currentBranch }.flatMap { branch in
            [
                PaletteItem(id: "switch:\(branch)", title: "Switch to \(branch)", subtitle: "Local branch", systemImage: "arrow.triangle.branch", section: "Branches", command: .switchBranch(branch)),
                PaletteItem(id: "build:\(branch)", title: "Build & Run \(branch)", subtitle: "On the target simulator", systemImage: "play", section: "Branches", command: .buildBranch(branch)),
                PaletteItem(id: "worktree:\(branch)", title: "Create a worktree for \(branch)", subtitle: "Local branch", systemImage: "plus.square.on.square", section: "Branches", command: .createWorktree(branch)),
            ]
        }
    }

    private static func worktreeItems(_ sources: PaletteSources) -> [PaletteItem] {
        sources.worktrees.filter { $0.kind != .main }.flatMap { worktree in
            let name = worktree.branch ?? URL(fileURLWithPath: worktree.path).lastPathComponent
            return [
                PaletteItem(id: "open:\(worktree.id)", title: "Open worktree \(name)", subtitle: ProjectPath(worktree.path).abbreviated, systemImage: "folder", section: "Worktrees", command: .openFolder(worktree.path)),
                PaletteItem(id: "buildwt:\(worktree.id)", title: "Build & Run worktree \(name)", subtitle: ProjectPath(worktree.path).abbreviated, systemImage: "play", section: "Worktrees", command: .buildWorktree(worktree.id)),
            ]
        }
    }

    private static func pullRequestItems(_ sources: PaletteSources) -> [PaletteItem] {
        sources.pullRequests.map { request in
            PaletteItem(
                id: "pr:\(request.iid)",
                title: "\(sources.requestNumber(request.iid)) \(request.title)",
                subtitle: "\(request.sourceBranch) → \(request.targetBranch) · \(request.author)",
                systemImage: "arrow.triangle.merge",
                section: "Pull requests",
                command: .showPullRequest(request.iid)
            )
        }
    }

    private static func sessionItems(_ sources: PaletteSources) -> [PaletteItem] {
        let available = sources.sessions.filter(\.folderExists)
        let favorites = available.filter { sources.favoriteSessionIDs.contains($0.id) }
        let others = available.filter { sources.favoriteSessionIDs.contains($0.id) == false }
        return (favorites + others).prefix(20).map { session in
            let isFavorite = sources.favoriteSessionIDs.contains(session.id)
            let provider = AISessionRowMapper.title(for: session.provider)
            return PaletteItem(
                id: "session:\(session.id)",
                title: "Resume \(session.title)",
                subtitle: isFavorite ? "Favorite · \(provider) · \(session.folderName)" : "\(provider) · \(session.folderName)",
                systemImage: isFavorite ? "star.fill" : "sparkles",
                section: "AI sessions",
                command: .resumeSession(command: session.terminalCommand, folder: session.cwd, title: "Resumed \(AISessionRowMapper.title(for: session.provider)) session")
            )
        }
    }

    private static func newSessionItems(_ sources: PaletteSources) -> [PaletteItem] {
        guard let project = sources.projects.first(where: { $0.id == sources.selectedProjectID }) else { return [] }
        return AIProvider.allCases.map { provider in
            PaletteItem(
                id: "newsession:\(provider.rawValue)",
                title: "Start \(AISessionRowMapper.toolTitle(for: provider)) in \(project.name)",
                subtitle: "A new session in \(project.path.abbreviatingHome)",
                systemImage: "plus.bubble",
                section: "AI sessions",
                command: .startSession(provider: provider, folder: project.path)
            )
        }
    }
}
