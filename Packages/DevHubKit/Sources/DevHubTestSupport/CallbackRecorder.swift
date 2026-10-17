import Synchronization

package final class CallbackRecorder<Value: Sendable>: Sendable {
    private let storage = Mutex<[Value]>([])

    package init() {}

    package var values: [Value] {
        storage.withLock { $0 }
    }

    package func append(_ value: Value) {
        storage.withLock { $0.append(value) }
    }
}
