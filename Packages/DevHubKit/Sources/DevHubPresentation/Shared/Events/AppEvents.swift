import Foundation
import DevHubDomain
import DevHubUI

@MainActor
final class AppEvents {
    private var handlers: [(id: UUID, handle: (AppEvent) -> Void)] = []

    func post(_ event: AppEvent) {
        for handler in handlers {
            handler.handle(event)
        }
    }

    func subscribe(_ handler: @escaping (AppEvent) -> Void) -> SubscriptionToken {
        let id = UUID()
        handlers.append((id, handler))
        return SubscriptionToken { [weak self] in
            guard let self else { return }
            handlers.removeAll { $0.id == id }
        }
    }
}
