import Foundation
import Observation

nonisolated final class ObservationProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var didChange = false

    var changed: Bool {
        lock.withLock { didChange }
    }

    @MainActor
    init(_ read: () -> Void) {
        withObservationTracking(read) { [self] in
            lock.withLock { didChange = true }
        }
    }
}
