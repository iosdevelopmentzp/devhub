import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class WindowLayout {
    static let defaultSize = CGSize(width: 720, height: 820)
    static let minimumSize = CGSize(width: 640, height: 560)
    static let margin: CGFloat = 12

    private(set) var size: CGSize
    private(set) var panelTopLeft: CGPoint?
    var openCount = 0
    var isShown = false

    @ObservationIgnored private let preferences: AppPreferences

    init(preferences: AppPreferences) {
        self.preferences = preferences
        size = preferences.value(CGSize.self, for: .windowSize) ?? Self.defaultSize
        panelTopLeft = preferences.value(CGPoint.self, for: .panelTopLeft)
    }

    func panelFrame(anchor: CGRect?, visibleFrames: [CGRect]) -> CGRect {
        let area = usableArea(anchor: anchor, visibleFrames: visibleFrames)
        let fitted = clamp(size, to: area.size)
        if fitted != size {
            setSize(fitted)
        }
        let start = panelTopLeft ?? anchorTopLeft(anchor: anchor, width: fitted.width, area: area)
        let topLeft = CGPoint(
            x: min(max(start.x, area.minX), area.maxX - fitted.width),
            y: min(max(start.y, area.minY + fitted.height), area.maxY)
        )
        if panelTopLeft != nil, topLeft != panelTopLeft {
            savePanelTopLeft(topLeft)
        }
        return CGRect(x: topLeft.x, y: topLeft.y - fitted.height, width: fitted.width, height: fitted.height)
    }

    func resize(to proposed: CGSize, topLeft: CGPoint, visibleFrame: CGRect) {
        let area = visibleFrame.insetBy(dx: Self.margin, dy: Self.margin)
        let room = CGSize(width: area.maxX - topLeft.x, height: topLeft.y - area.minY)
        setSize(clamp(proposed, to: room))
    }

    func savePanelTopLeft(_ point: CGPoint) {
        panelTopLeft = point
        preferences.setValue(point, for: .panelTopLeft)
    }

    func setSize(_ newSize: CGSize) {
        guard newSize != size else { return }
        size = newSize
        preferences.setValue(newSize, for: .windowSize)
    }

    func reset() {
        panelTopLeft = nil
        preferences.setValue(nil as CGPoint?, for: .panelTopLeft)
        setSize(Self.defaultSize)
    }

    func resetPosition() {
        panelTopLeft = nil
        preferences.setValue(nil as CGPoint?, for: .panelTopLeft)
    }

    private func usableArea(anchor: CGRect?, visibleFrames: [CGRect]) -> CGRect {
        let probe = panelTopLeft ?? anchor.map { CGPoint(x: $0.midX, y: $0.midY) }
        let screen = probe.flatMap { point in
            visibleFrames.first { point.x >= $0.minX && point.x <= $0.maxX }
        }
        let frame = screen ?? visibleFrames.first ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return frame.insetBy(dx: Self.margin, dy: Self.margin)
    }

    private func anchorTopLeft(anchor: CGRect?, width: CGFloat, area: CGRect) -> CGPoint {
        guard let anchor else {
            return CGPoint(x: area.maxX - width, y: area.maxY)
        }
        return CGPoint(x: anchor.midX - width / 2, y: anchor.minY - 4)
    }

    private func clamp(_ value: CGSize, to limit: CGSize) -> CGSize {
        CGSize(
            width: min(max(value.width, min(Self.minimumSize.width, limit.width)), limit.width),
            height: min(max(value.height, min(Self.minimumSize.height, limit.height)), limit.height)
        )
    }
}
