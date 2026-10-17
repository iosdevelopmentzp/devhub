import AppKit
import SwiftUI

package struct WindowAppearance: NSViewRepresentable {
    package let name: NSAppearance.Name

    package init(name: NSAppearance.Name) {
        self.name = name
    }

    package func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.appearance = NSAppearance(named: name)
        }
        return view
    }

    package func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.appearance = NSAppearance(named: name)
        }
    }
}
