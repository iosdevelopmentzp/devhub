import DevHubDomain
import DevHubUI

struct TabItem: Identifiable, Equatable {
    let id: TabID
    let title: String
    let systemImage: String
    let searchPrompt: String?
}
