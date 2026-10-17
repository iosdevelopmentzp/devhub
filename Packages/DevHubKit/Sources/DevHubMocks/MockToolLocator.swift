import Foundation
import DevHubDomain

struct MockToolLocator: ToolLocating {
    func isInstalled(_ executable: String) -> Bool {
        true
    }

    func fileExists(atPath path: String) -> Bool {
        true
    }
}
