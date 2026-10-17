import SwiftUI

struct Feature: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let searchPrompt: String
    let content: () -> AnyView
}

enum FeatureRegistry {
    static let all: [Feature] = [
        Feature(id: "home", title: "Home", systemImage: "house", searchPrompt: "Search actions and scripts") { AnyView(HomeView()) },
        Feature(id: "git", title: "Git", systemImage: "arrow.triangle.branch", searchPrompt: "Search branches, commits, files") { AnyView(GitView()) },
        Feature(id: "worktrees", title: "Worktrees", systemImage: "square.stack.3d.up", searchPrompt: "Search worktrees") { AnyView(WorktreesView()) },
        Feature(id: "simulators", title: "Simulators", systemImage: "iphone", searchPrompt: "Search simulators") { AnyView(SimulatorsView()) },
        Feature(id: "logs", title: "Logs", systemImage: "text.alignleft", searchPrompt: "Search log lines") { AnyView(LogsView()) },
        Feature(id: "ai", title: "AI", systemImage: "sparkles", searchPrompt: "Search sessions") { AnyView(AIView()) },
        Feature(id: "settings", title: "Settings", systemImage: "gearshape", searchPrompt: "Search settings") { AnyView(SettingsView()) }
    ]

    static func feature(id: String) -> Feature? {
        all.first { $0.id == id }
    }
}
