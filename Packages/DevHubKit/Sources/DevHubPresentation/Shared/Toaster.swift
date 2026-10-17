import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class Toaster {
    @ObservationIgnored private let write: (String) -> Void

    private(set) var text: String?

    @ObservationIgnored private var hideTask: Task<Void, Never>?

    init(write: @escaping (String) -> Void) {
        self.write = write
    }

    func copy(_ value: String) {
        copy(value, label: value)
    }

    func copy(_ value: String, label: String) {
        write(value)
        let preview = label.count > 48 ? String(label.prefix(45)) + "…" : label
        show("Copied: \(preview)")
    }

    func show(_ message: String) {
        hideTask?.cancel()
        text = message
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            guard Task.isCancelled == false else { return }
            self?.text = nil
        }
    }
}
