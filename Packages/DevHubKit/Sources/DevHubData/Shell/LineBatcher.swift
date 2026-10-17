import Foundation
import DevHubDomain

final class LineBatcher: @unchecked Sendable {
    private let id: UUID
    private let recorder: any CommandRecording
    private let lock = NSLock()
    private var pending: [String] = []
    private var isScheduled = false

    init(id: UUID, recorder: any CommandRecording) {
        self.id = id
        self.recorder = recorder
    }

    func add(_ line: String) {
        lock.withLock {
            pending.append(line)
            guard isScheduled == false else { return }
            isScheduled = true
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) { [self] in flush() }
        }
    }

    func flush() {
        let lines: [String] = lock.withLock {
            defer {
                pending = []
                isScheduled = false
            }
            return pending
        }
        guard lines.isEmpty == false else { return }
        recorder.record(CommandEvent(id: id, payload: .output(lines)))
    }
}
