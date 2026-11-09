import CoreGraphics
import Foundation

enum DiffViewportPolicy {
    static let lineHeightFactor: CGFloat = 1.3
    static let linePadding: CGFloat = 1
    static let framePadding: CGFloat = 10

    static func isNear(_ frame: CGRect, visibleRect: CGRect?) -> Bool {
        guard let visibleRect, visibleRect.isEmpty == false else { return true }
        guard frame.isEmpty == false else { return false }
        return frame.intersects(visibleRect.insetBy(dx: 0, dy: -visibleRect.height))
    }

    static func nearIDs(frames: [String: CGRect], visibleRect: CGRect?) -> Set<String> {
        Set(frames.filter { isNear($0.value, visibleRect: visibleRect) }.keys)
    }

    static func estimatedHeight(of model: DiffModel, fontSize: CGFloat) -> CGFloat {
        var lineCount = 1
        if case .lines(let lines, _) = model {
            lineCount = max(lines.count, 1)
        }
        return CGFloat(lineCount) * (fontSize * lineHeightFactor + linePadding) + framePadding
    }
}
