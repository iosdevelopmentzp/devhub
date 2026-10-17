import AppKit
import Observation

@MainActor
@Observable
package final class HintCenter {
    package private(set) var current: Hint?

    @ObservationIgnored private var lastHidden = Date.distantPast
    @ObservationIgnored private var monitor: Any?

    package init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown, .scrollWheel]) { [weak self] event in
            self?.hideCurrent()
            return event
        }
    }

    package var delay: Duration {
        let isWarm = current != nil || Date.now.timeIntervalSince(lastHidden) < 0.8
        return isWarm ? .milliseconds(60) : .milliseconds(550)
    }

    package func show(_ hint: Hint) {
        current = hint
    }

    package func hide(id: UUID) {
        guard current?.id == id else { return }
        hideCurrent()
    }

    private func hideCurrent() {
        guard current != nil else { return }
        current = nil
        lastHidden = .now
    }
}
