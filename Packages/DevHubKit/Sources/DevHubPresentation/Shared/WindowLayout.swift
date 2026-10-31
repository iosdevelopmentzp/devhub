import AppKit
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class WindowLayout {
    static let minimumSize = CGSize(width: 640, height: 560)
    static let defaultSize = CGSize(width: 720, height: 820)
    static let pinnedAutosaveName = "DevHubPinnedWindow"
    static let mainAutosaveName = "DevHubMainWindow"
    static let pullRequestAutosaveName = "DevHubPullRequestWindow"
    static let screenInset: CGFloat = 12

    var size: CGSize {
        didSet {
            guard size != oldValue else { return }
            store.set([Double(size.width), Double(size.height)], forKey: Keys.size)
        }
    }

    var panelTopLeft: CGPoint? {
        didSet {
            if let panelTopLeft {
                store.set([Double(panelTopLeft.x), Double(panelTopLeft.y)], forKey: Keys.panelTopLeft)
            } else {
                store.remove(forKey: Keys.panelTopLeft)
            }
        }
    }

    var openCount = 0

    var isWindowOpen: Bool {
        didSet {
            guard isWindowOpen != oldValue else { return }
            store.set(isWindowOpen, forKey: Keys.isWindowOpen)
        }
    }

    @ObservationIgnored private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
        isWindowOpen = store.bool(forKey: Keys.isWindowOpen)
        let stored = store.doubles(forKey: Keys.size)
        if let stored, stored.count == 2 {
            size = Self.clamped(CGSize(width: stored[0], height: stored[1]))
        } else {
            size = Self.defaultSize
        }
        let point = store.doubles(forKey: Keys.panelTopLeft)
        if let point, point.count == 2 {
            panelTopLeft = CGPoint(x: point[0], y: point[1])
        }
    }

    func panelFrame(anchor: CGPoint, anchorScreen: NSScreen?) -> NSRect {
        let topLeft = panelTopLeft ?? anchor
        guard let area = Self.usableArea(of: Self.screen(containing: topLeft) ?? anchorScreen ?? NSScreen.main) else {
            return NSRect(x: topLeft.x, y: topLeft.y - size.height, width: size.width, height: size.height)
        }
        let fitted = Self.clamped(size, to: area.size)
        if fitted != size {
            size = fitted
        }
        let point = CGPoint(
            x: min(max(topLeft.x, area.minX), area.maxX - fitted.width),
            y: min(max(topLeft.y, area.minY + fitted.height), area.maxY)
        )
        if panelTopLeft != nil, point != panelTopLeft {
            panelTopLeft = point
        }
        return NSRect(x: point.x, y: point.y - fitted.height, width: fitted.width, height: fitted.height)
    }

    func fit(_ window: NSWindow) {
        let frame = panelFrame(anchor: CGPoint(x: window.frame.minX, y: window.frame.maxY), anchorScreen: window.screen)
        if window.frame != frame {
            window.setFrame(frame, display: true)
        }
    }

    func resize(to proposed: CGSize, in window: NSWindow?) {
        guard let window, let area = Self.usableArea(of: Self.screen(containing: CGPoint(x: window.frame.minX, y: window.frame.maxY)) ?? window.screen) else {
            size = Self.clamped(proposed)
            return
        }
        let room = CGSize(width: area.maxX - window.frame.minX, height: window.frame.maxY - area.minY)
        size = Self.clamped(proposed, to: room)
    }

    func reset() {
        size = Self.defaultSize
    }

    static func clamped(_ proposed: CGSize) -> CGSize {
        clamped(proposed, to: usableArea(of: NSScreen.main)?.size ?? CGSize(width: 1440, height: 900))
    }

    static func usableArea(of screen: NSScreen?) -> NSRect? {
        screen?.visibleFrame.insetBy(dx: screenInset, dy: screenInset)
    }

    static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(point) }
    }

    static func clamped(_ proposed: CGSize, to room: CGSize) -> CGSize {
        CGSize(
            width: min(max(proposed.width, minimumSize.width), room.width).rounded(.down),
            height: min(max(proposed.height, minimumSize.height), room.height).rounded(.down)
        )
    }

    private enum Keys {
        static let size = "window.size"
        static let panelTopLeft = "window.panelTopLeft"
        static let isWindowOpen = "window.isOpen"
    }
}
