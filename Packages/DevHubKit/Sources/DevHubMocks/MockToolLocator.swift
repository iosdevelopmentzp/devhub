import Foundation
import DevHubDomain

struct MockToolLocator: ToolLocating {
    func isInstalled(_ executable: String) -> Bool {
        true
    }
}
