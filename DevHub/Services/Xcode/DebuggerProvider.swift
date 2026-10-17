import Foundation

nonisolated struct AttachRequest: Hashable, Sendable {
    var processID: Int
    var simulatorID: String
    var container: String
}

nonisolated struct AttachFailure: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? { message }
}

nonisolated protocol DebuggerAttaching: Sendable {
    func isTrusted() -> Bool
    func requestAccess()
    func attach(_ request: AttachRequest, onStep: @escaping @Sendable (String) -> Void) async throws
}

nonisolated struct MockDebuggerAttacher: DebuggerAttaching {
    func isTrusted() -> Bool { true }
    func requestAccess() {}
    func attach(_ request: AttachRequest, onStep: @escaping @Sendable (String) -> Void) async throws {}
}

nonisolated enum AttachAdvice {
    static func manualSteps(processID: Int) -> String {
        "In Xcode choose Debug > Attach to Process by PID or Name…, type \(processID) and press Attach."
    }

    static let accessMessage = "Run & Attach needs Accessibility access for DevHub. Open System Settings > Privacy & Security > Accessibility and turn DevHub on."
}
