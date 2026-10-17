import AppKit
import SwiftUI

package struct HostWindowReader: NSViewRepresentable {
    package let onWindow: (NSWindow?) -> Void

    package init(onWindow: @escaping (NSWindow?) -> Void) {
        self.onWindow = onWindow
    }

    package func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onWindow(view.window)
        }
        return view
    }

    package func updateNSView(_ nsView: NSView, context: Context) {}
}
