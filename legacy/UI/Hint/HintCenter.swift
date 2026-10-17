import AppKit
import Observation

struct Hint: Equatable {
    let owner: UUID
    let text: String
    let frame: CGRect
}

@MainActor
@Observable
final class HintCenter {
    private(set) var current: Hint?

    @ObservationIgnored private var showTask: Task<Void, Never>?
    @ObservationIgnored private var lastChange = Date.distantPast
    @ObservationIgnored private var monitor: Any?

    func hoverChanged(owner: UUID, text: String, frame: CGRect, isHovering: Bool) {
        showTask?.cancel()
        guard isHovering else {
            hide(owner: owner)
            return
        }
        installMonitor()
        let delay = Date().timeIntervalSince(lastChange) < 0.8 ? 0.06 : 0.55
        showTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard Task.isCancelled == false else { return }
            guard let self else { return }
            current = Hint(owner: owner, text: text, frame: frame)
            lastChange = Date()
        }
    }

    func frameChanged(owner: UUID, frame: CGRect) {
        guard let current, current.owner == owner else { return }
        self.current = Hint(owner: owner, text: current.text, frame: frame)
    }

    func hide(owner: UUID) {
        guard current?.owner == owner else { return }
        hideAll()
    }

    func hideAll() {
        showTask?.cancel()
        guard current != nil else { return }
        current = nil
        lastChange = Date()
    }

    private func installMonitor() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown, .scrollWheel]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.hideAll()
            }
            return event
        }
    }
}
