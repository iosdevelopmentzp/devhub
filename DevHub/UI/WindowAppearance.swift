import AppKit
import SwiftUI

struct WindowAppearance: NSViewRepresentable {
    let name: NSAppearance.Name

    func makeNSView(context: Context) -> AppearanceView {
        AppearanceView(name: name)
    }

    func updateNSView(_ view: AppearanceView, context: Context) {
        view.name = name
        view.apply()
    }
}

final class AppearanceView: NSView {
    var name: NSAppearance.Name

    init(name: NSAppearance.Name) {
        self.name = name
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        apply()
    }

    func apply() {
        window?.appearance = NSAppearance(named: name)
    }
}
