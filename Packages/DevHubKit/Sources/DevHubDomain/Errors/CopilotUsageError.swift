import Foundation

package enum CopilotUsageError: LocalizedError, Hashable, Sendable {
    case rejected
    case http(Int)
    case malformedResponse

    package var errorDescription: String? {
        switch self {
        case .rejected:
            "GitHub rejected the Copilot token. Run `copilot` and sign in again."
        case .http(let code):
            "Copilot usage request failed (HTTP \(code))."
        case .malformedResponse:
            "Copilot usage response had an unexpected format."
        }
    }
}
