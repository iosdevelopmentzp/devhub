import Foundation
import Observation

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let tint: Tint
}

@MainActor
@Observable
final class Toaster {
    private(set) var current: Toast?

    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    func show(_ text: String, tint: Tint) {
        let toast = Toast(text: text, tint: tint)
        current = toast
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard Task.isCancelled == false else { return }
            guard let self else { return }
            if current == toast {
                current = nil
            }
        }
    }

    func copy(_ value: String, label: String) {
        Clipboard.write(value)
        show("Copied: \(label)", tint: .green)
    }
}
