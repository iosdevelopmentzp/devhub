import SwiftUI
import DevHubDomain
import DevHubUI

struct Feature: Identifiable {
    let id: FeatureID
    let title: String
    let systemImage: String
    let showsInTabBar: Bool
    let searchPrompt: String?
    let makeView: () -> AnyView

    init<Content: View>(
        id: FeatureID,
        title: String,
        systemImage: String,
        showsInTabBar: Bool = true,
        searchPrompt: String?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.showsInTabBar = showsInTabBar
        self.searchPrompt = searchPrompt
        self.makeView = { AnyView(content()) }
    }
}
