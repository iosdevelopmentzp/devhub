import AppKit
import DevHubDomain
import DevHubUI

final class MainWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: WindowLayout.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        title = "DevHub"
        isReleasedWhenClosed = false
        contentMinSize = WindowLayout.minimumSize
        collectionBehavior.insert(.moveToActiveSpace)
        appearance = NSAppearance(named: .aqua)
    }
}
