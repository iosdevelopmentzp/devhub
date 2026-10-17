import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var dependencies: AppDependencies?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let live = AppDependencies.live()
        dependencies = live
        DebugLaunch.apply(to: live)
    }
}
