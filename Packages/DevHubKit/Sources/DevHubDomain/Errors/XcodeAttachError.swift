import Foundation

package enum XcodeAttachError: LocalizedError, Sendable {
    case accessibilityNotGranted
    case noProject(String)
    case xcodeDidNotOpen
    case script(String)
    case stillStopped(Int32)

    package var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            "DevHub needs Accessibility access to drive Xcode's Debug menu. Allow DevHub in System Settings → Privacy & Security → Accessibility, then try again."
        case .noProject(let path):
            "No .xcworkspace or .xcodeproj in \(path)."
        case .xcodeDidNotOpen:
            "Xcode did not show a window within 150 s."
        case .script(let message):
            "Xcode attach failed: \(message)"
        case .stillStopped(let pid):
            "Process \(pid) is still waiting for a debugger: Xcode attached to something else or nothing. In Xcode: Debug → Attach to Process by PID or Name… → \(pid) → Attach."
        }
    }
}
