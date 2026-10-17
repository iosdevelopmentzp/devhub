import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    var hotKey: HotKeyChoice = .optionCommandD {
        didSet { save(hotKey.rawValue, for: .hotKey) }
    }

    var showDockIcon = false {
        didSet { save(showDockIcon, for: .showDockIcon) }
    }

    var terminal: TerminalApp = .terminal {
        didSet { save(terminal.rawValue, for: .terminalApp) }
    }

    var editor: EditorApp = .xcode {
        didSet { save(editor.rawValue, for: .editorApp) }
    }

    var showUsageStrip = true {
        didSet { save(showUsageStrip, for: .showUsageStrip) }
    }

    var showClaudeUsageInMenuBar = false {
        didSet { save(showClaudeUsageInMenuBar, for: .usageMenuBarClaude) }
    }

    var showCopilotUsageInMenuBar = false {
        didSet { save(showCopilotUsageInMenuBar, for: .usageMenuBarCopilot) }
    }

    @ObservationIgnored private let preferences: AppPreferences
    @ObservationIgnored private var isLoading = true

    init(preferences: AppPreferences) {
        self.preferences = preferences
        load()
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        hotKey = preferences.string(.hotKey).flatMap(HotKeyChoice.init(rawValue:)) ?? .optionCommandD
        showDockIcon = preferences.bool(.showDockIcon) ?? false
        terminal = preferences.string(.terminalApp).flatMap(TerminalApp.init(rawValue:)) ?? .terminal
        editor = preferences.string(.editorApp).flatMap(EditorApp.init(rawValue:)) ?? .xcode
        showUsageStrip = preferences.bool(.showUsageStrip) ?? true
        showClaudeUsageInMenuBar = preferences.bool(.usageMenuBarClaude) ?? false
        showCopilotUsageInMenuBar = preferences.bool(.usageMenuBarCopilot) ?? false
    }

    private func save(_ value: String, for key: AppPreferences.Key) {
        guard isLoading == false else { return }
        preferences.set(value, for: key)
    }

    private func save(_ value: Bool, for key: AppPreferences.Key) {
        guard isLoading == false else { return }
        preferences.set(value, for: key)
    }
}
