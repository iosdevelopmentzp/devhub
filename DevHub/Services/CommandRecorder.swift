import Foundation

nonisolated final class CommandRecorder: @unchecked Sendable {
    static let shared = CommandRecorder()

    private let lock = NSLock()
    private var sink: (@MainActor (CommandEvent) -> Void)?

    func attach(_ sink: @escaping @MainActor (CommandEvent) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        self.sink = sink
    }

    func send(_ event: CommandEvent) {
        lock.lock()
        let sink = self.sink
        lock.unlock()
        guard let sink else { return }
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                sink(event)
            }
        }
    }
}

nonisolated final class LineBatcher: @unchecked Sendable {
    private let id: UUID
    private let recorder: CommandRecorder
    private let recordsOutput: Bool
    private let lock = NSLock()
    private var pending: [String] = []
    private var isFlushScheduled = false

    init(id: UUID, recorder: CommandRecorder, recordsOutput: Bool) {
        self.id = id
        self.recorder = recorder
        self.recordsOutput = recordsOutput
    }

    func add(_ line: String) {
        guard recordsOutput else { return }
        lock.lock()
        defer { lock.unlock() }
        pending.append(line)
        guard isFlushScheduled == false else { return }
        isFlushScheduled = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) { [self] in
            flush()
        }
    }

    func flush() {
        lock.lock()
        defer { lock.unlock() }
        isFlushScheduled = false
        guard pending.isEmpty == false else { return }
        recorder.send(.output(id: id, lines: pending))
        pending.removeAll()
    }
}
