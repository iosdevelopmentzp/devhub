import AppKit

package final class FileDropView: NSView {
    private let accepts: (URL) -> Bool
    private let onTarget: (Bool) -> Void
    private let onDrop: ([URL]) -> Void
    private let onClick: () -> Void

    package init(accepts: @escaping (URL) -> Bool, onTarget: @escaping (Bool) -> Void, onDrop: @escaping ([URL]) -> Void, onClick: @escaping () -> Void) {
        self.accepts = accepts
        self.onTarget = onTarget
        self.onDrop = onDrop
        self.onClick = onClick
        super.init(frame: .zero)
        autoresizingMask = [.width, .height]
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        nil
    }

    package override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    package override func mouseDown(with event: NSEvent) {
        onClick()
    }

    package override func rightMouseDown(with event: NSEvent) {
        onClick()
    }

    package override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let isAccepted = urls(in: sender).contains(where: accepts)
        onTarget(isAccepted)
        return isAccepted ? .copy : []
    }

    package override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        onTarget(false)
    }

    package override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        onTarget(false)
        let accepted = urls(in: sender).filter(accepts)
        guard accepted.isEmpty == false else { return false }
        onDrop(accepted)
        return true
    }

    private func urls(in info: any NSDraggingInfo) -> [URL] {
        info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }
}
