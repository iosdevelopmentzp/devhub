import SwiftUI
import DevHubDomain
import DevHubUI

enum FeatureRegistry {
    static let defaultFeatureID: FeatureID = .home

    static let all: [Feature] = [
        Feature(id: .home, title: "Home", systemImage: "house", searchPrompt: "Search actions and scripts") { HomeView() },
        Feature(id: .git, title: "Git", systemImage: "arrow.triangle.pull", searchPrompt: "Search branches, commits, files") { GitView() },
        Feature(id: .pullRequests, title: "Pull Requests", systemImage: "arrow.triangle.merge", searchPrompt: "Search pull requests") { PullRequestsView() },
        Feature(id: .worktrees, title: "Worktrees", systemImage: "arrow.triangle.branch", searchPrompt: "Search worktrees") { WorktreesView() },
        Feature(id: .simulators, title: "Simulators", systemImage: "iphone", searchPrompt: "Search simulators") { SimulatorsView() },
        Feature(id: .logs, title: "Logs", systemImage: "text.alignleft", searchPrompt: "Search log lines") { LogsView() },
        Feature(id: .network, title: "Network", systemImage: "network", searchPrompt: "Filter requests") { NetworkView() },
        Feature(id: .ai, title: "AI", systemImage: "sparkles", searchPrompt: "Search sessions") { AISessionsView() },
        Feature(id: .utils, title: "Utils", systemImage: "hammer", searchPrompt: nil) { UtilsView() },
        Feature(id: .notifications, title: "Notifications", systemImage: "bell", showsInTabBar: false, searchPrompt: "Search notifications") { NotificationsView() },
        Feature(id: .settings, title: "Settings", systemImage: "gearshape", showsInTabBar: false, searchPrompt: nil) { SettingsView() }
    ]

    static var tabBarFeatures: [Feature] {
        all.filter(\.showsInTabBar)
    }

    static func feature(_ id: FeatureID) -> Feature {
        guard let feature = featuresByID[id] else {
            preconditionFailure("No feature registered for \(id)")
        }
        return feature
    }

    private static let featuresByID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
