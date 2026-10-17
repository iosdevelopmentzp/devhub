import DevHubComposition
import SwiftUI

@main
struct DevHubApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
