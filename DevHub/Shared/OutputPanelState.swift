import Foundation
import Observation

@MainActor
@Observable
final class OutputPanelState {
    var isVisible = false
    var searchText = ""
    var showReads: Bool {
        didSet { preferences.set(showReads, for: .showReadCommands) }
    }

    @ObservationIgnored private let preferences: AppPreferences

    init(preferences: AppPreferences, events: AppEvents) {
        self.preferences = preferences
        showReads = preferences.bool(.showReadCommands) ?? false
        events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .commandFailed = event else { return }
            isVisible = true
        }
    }

    func toggle() {
        isVisible.toggle()
    }

    func visibleEntries(_ entries: [CommandEntry]) -> [CommandEntry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return entries.filter { entry in
            guard showReads || entry.kind != .read else { return false }
            guard query.isEmpty == false else { return true }
            return matches(entry, query: query)
        }
    }

    private func matches(_ entry: CommandEntry, query: String) -> Bool {
        if entry.command.localizedCaseInsensitiveContains(query) {
            return true
        }
        if entry.error?.localizedCaseInsensitiveContains(query) == true {
            return true
        }
        return entry.lines.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}
