import Foundation

nonisolated enum TerminalApp: String, CaseIterable, Identifiable, Sendable {
    case terminal
    case iterm
    case ghostty
    case warp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terminal: "Terminal"
        case .iterm: "iTerm2"
        case .ghostty: "Ghostty"
        case .warp: "Warp"
        }
    }

    var applicationName: String {
        switch self {
        case .terminal: "Terminal"
        case .iterm: "iTerm"
        case .ghostty: "Ghostty"
        case .warp: "Warp"
        }
    }
}

nonisolated enum EditorApp: String, CaseIterable, Identifiable, Sendable {
    case xcode
    case vscode
    case cursor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .xcode: "Xcode"
        case .vscode: "VS Code"
        case .cursor: "Cursor"
        }
    }

    var applicationName: String {
        switch self {
        case .xcode: "Xcode"
        case .vscode: "Visual Studio Code"
        case .cursor: "Cursor"
        }
    }
}

nonisolated enum HotKeyChoice: String, CaseIterable, Identifiable, Sendable {
    case optionCommandD
    case controlOptionSpace
    case controlOptionD
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .optionCommandD: "⌥⌘D"
        case .controlOptionSpace: "⌃⌥Space"
        case .controlOptionD: "⌃⌥D"
        case .off: "Off"
        }
    }
}
