import Foundation
import DevHubDomain

enum UsageProvidersText {
    static func title(for providers: UsageProviders) -> String {
        switch providers {
        case .all: "Claude and Copilot"
        case .claude: "Claude only"
        case .copilot: "Copilot only"
        case .none: "Off"
        }
    }
}
