import Foundation
import DevHubDomain

struct MockToolLocator: ToolLocating {
    func isInstalled(_ executable: String) -> Bool {
        true
    }

    func path(of executable: String) -> String? {
        "/usr/bin/" + executable
    }

    func fileExists(atPath path: String) -> Bool {
        true
    }
}
