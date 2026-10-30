import Foundation
import DevHubUI

enum TestRunText {
    static func counts(passed: Int, failed: Int, skipped: Int) -> String {
        guard passed + failed + skipped > 0 else { return "No tests ran" }
        return [
            passed > 0 ? "\(passed) passed" : nil,
            failed > 0 ? "\(failed) failed" : nil,
            skipped > 0 ? "\(skipped) skipped" : nil
        ].compactMap { $0 }.joined(separator: " · ")
    }
}
