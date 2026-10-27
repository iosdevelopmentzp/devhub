import DevHubComposition
import SwiftUI

@main
struct DevHubApp: App {
    @NSApplicationDelegateAdaptor(AppContainer.self) private var container

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
