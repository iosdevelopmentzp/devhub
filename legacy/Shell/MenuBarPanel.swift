import AppKit

final class MenuBarPanel: NSPanel {
    var onCancel: () -> Void = {}

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 720, height: 820),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .statusBar
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .none
        isMovable = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel()
    }
}
