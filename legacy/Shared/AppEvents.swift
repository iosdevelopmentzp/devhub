import Foundation

enum AppEvent {
    case projectChanged
    case configChanged
    case branchesChanged
    case worktreesChanged
    case simulatorsChanged
    case commandFailed(String)
}

@MainActor
final class AppEvents {
    private var handlers: [(AppEvent) -> Void] = []

    func subscribe(_ handler: @escaping (AppEvent) -> Void) {
        handlers.append(handler)
    }

    func post(_ event: AppEvent) {
        for handler in handlers {
            handler(event)
        }
    }
}
