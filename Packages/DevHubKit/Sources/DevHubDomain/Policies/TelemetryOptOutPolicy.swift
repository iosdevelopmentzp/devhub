import Foundation

package enum TelemetryOptOutPolicy {
    package static let environment: [String: String] = [
        "DO_NOT_TRACK": "1",
        "HOMEBREW_NO_ANALYTICS": "1",
        "GH_TELEMETRY": "false",
        "GH_NO_UPDATE_NOTIFIER": "1",
        "CIRCLE_NO_TELEMETRY": "1",
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    ]
}
