#if DEBUG
import AppKit

package extension AppWindows {
    func debugShowPanel() {
        showPanel()
    }

    func debugSnapshot(to path: String) {
        guard let view = panel.contentView, let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: representation)
        try? representation.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}
#endif
