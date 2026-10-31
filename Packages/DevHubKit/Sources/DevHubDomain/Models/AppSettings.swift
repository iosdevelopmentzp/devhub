import Foundation

package struct AppSettings: Hashable, Codable, Sendable {
    package var showDockIcon = false
    package var showUsageStrip = true
    package var showUsageInMenuBar = true
    package var usageProviders = UsageProviders.all
    package var showReviewCountInMenuBar = true
    package var globalShortcut = GlobalShortcut.optionCommandD
    package var scriptsFolder = "~/.devhub/scripts"
    package var editor = "Xcode"
    package var terminal = "Terminal"
    package var ticketURLTemplate = ""
    package var autoFetchMinutes = 0
    package var notifyWhenPanelClosed = true
    package var mutedNotifications: Set<NotificationKind> = []
    package var windowMode = WindowMode.panel

    package init(
        showDockIcon: Bool = false,
        showUsageStrip: Bool = true,
        showUsageInMenuBar: Bool = true,
        usageProviders: UsageProviders = UsageProviders.all,
        showReviewCountInMenuBar: Bool = true,
        globalShortcut: GlobalShortcut = GlobalShortcut.optionCommandD,
        scriptsFolder: String = "~/.devhub/scripts",
        editor: String = "Xcode",
        terminal: String = "Terminal",
        ticketURLTemplate: String = "",
        autoFetchMinutes: Int = 0,
        notifyWhenPanelClosed: Bool = true,
        mutedNotifications: Set<NotificationKind> = [],
        windowMode: WindowMode = WindowMode.panel
    ) {
        self.showDockIcon = showDockIcon
        self.showUsageStrip = showUsageStrip
        self.showUsageInMenuBar = showUsageInMenuBar
        self.usageProviders = usageProviders
        self.showReviewCountInMenuBar = showReviewCountInMenuBar
        self.globalShortcut = globalShortcut
        self.scriptsFolder = scriptsFolder
        self.editor = editor
        self.terminal = terminal
        self.ticketURLTemplate = ticketURLTemplate
        self.autoFetchMinutes = autoFetchMinutes
        self.notifyWhenPanelClosed = notifyWhenPanelClosed
        self.mutedNotifications = mutedNotifications
        self.windowMode = windowMode
    }
}

extension AppSettings {
    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        self.init(
            showDockIcon: try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? defaults.showDockIcon,
            showUsageStrip: try container.decodeIfPresent(Bool.self, forKey: .showUsageStrip) ?? defaults.showUsageStrip,
            showUsageInMenuBar: try container.decodeIfPresent(Bool.self, forKey: .showUsageInMenuBar) ?? defaults.showUsageInMenuBar,
            usageProviders: (try? container.decodeIfPresent(UsageProviders.self, forKey: .usageProviders)) ?? defaults.usageProviders,
            showReviewCountInMenuBar: try container.decodeIfPresent(Bool.self, forKey: .showReviewCountInMenuBar) ?? defaults.showReviewCountInMenuBar,
            globalShortcut: try container.decodeIfPresent(GlobalShortcut.self, forKey: .globalShortcut) ?? defaults.globalShortcut,
            scriptsFolder: try container.decodeIfPresent(String.self, forKey: .scriptsFolder) ?? defaults.scriptsFolder,
            editor: try container.decodeIfPresent(String.self, forKey: .editor) ?? defaults.editor,
            terminal: try container.decodeIfPresent(String.self, forKey: .terminal) ?? defaults.terminal,
            ticketURLTemplate: try container.decodeIfPresent(String.self, forKey: .ticketURLTemplate) ?? defaults.ticketURLTemplate,
            autoFetchMinutes: try container.decodeIfPresent(Int.self, forKey: .autoFetchMinutes) ?? defaults.autoFetchMinutes,
            notifyWhenPanelClosed: try container.decodeIfPresent(Bool.self, forKey: .notifyWhenPanelClosed) ?? defaults.notifyWhenPanelClosed,
            mutedNotifications: (try? container.decodeIfPresent(Set<NotificationKind>.self, forKey: .mutedNotifications)) ?? defaults.mutedNotifications,
            windowMode: (try? container.decodeIfPresent(WindowMode.self, forKey: .windowMode)) ?? defaults.windowMode
        )
    }
}

extension AppSettings {
    package func notifies(_ kind: NotificationKind) -> Bool {
        mutedNotifications.contains(kind) == false
    }

    package mutating func setNotifies(_ kind: NotificationKind, _ enabled: Bool) {
        if enabled {
            mutedNotifications.remove(kind)
        } else {
            mutedNotifications.insert(kind)
        }
    }
}
