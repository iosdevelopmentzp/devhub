import SwiftUI
import DevHubDomain
import DevHubUI

struct WindowFrame: ViewModifier {
    let layout: WindowLayout
    let isPinnedWindow: Bool

    @State private var window: NSWindow?

    func body(content: Content) -> some View {
        if isPinnedWindow {
            content
                .frame(
                    minWidth: WindowLayout.minimumSize.width,
                    idealWidth: layout.size.width,
                    maxWidth: .infinity,
                    minHeight: WindowLayout.minimumSize.height,
                    idealHeight: layout.size.height,
                    maxHeight: .infinity
                )
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                    guard window != nil else { return }
                    layout.resize(to: size, in: nil)
                }
                .background(HostWindowReader { window = $0 })
        } else {
            content
                .frame(width: layout.size.width, height: layout.size.height)
        }
    }
}
