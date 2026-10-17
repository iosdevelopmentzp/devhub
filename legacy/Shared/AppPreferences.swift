import Foundation

final class AppPreferences {
    enum Key: String {
        case windowSize = "window.size"
        case panelTopLeft = "window.panelTopLeft"
        case selectedTab = "navigator.selectedTab"
        case projectPath = "project.path"
        case projects = "projects.list"
        case actionLastRun = "actions.lastRun"
        case actionInputs = "actions.inputs"
        case hotKey = "settings.hotKey"
        case showDockIcon = "settings.showDockIcon"
        case terminalApp = "settings.terminalApp"
        case editorApp = "settings.editorApp"
        case showReadCommands = "output.showReadCommands"
        case logStreams = "logs.streams"
        case aiProviderFilter = "ai.providerFilter"
        case aiScope = "ai.scope"
        case showUsageStrip = "settings.showUsageStrip"
        case usageMenuBarClaude = "settings.usageMenuBarClaude"
        case usageMenuBarCopilot = "settings.usageMenuBarCopilot"
        case gitSegment = "git.segment"
        case simulatorTarget = "simulators.target"
        case simulatorFavorites = "simulators.favorites"
        case runOptions = "simulators.runOptions"
        case recentLinks = "simulators.recentLinks"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func string(_ key: Key) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func bool(_ key: Key) -> Bool? {
        defaults.object(forKey: key.rawValue) as? Bool
    }

    func set(_ value: String?, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func set(_ value: Bool, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    func value<T: Decodable>(_ type: T.Type, for key: Key) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func setValue<T: Encodable>(_ value: T?, for key: Key) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }
        defaults.set(try? JSONEncoder().encode(value), forKey: key.rawValue)
    }
}
