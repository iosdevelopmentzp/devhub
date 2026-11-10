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

    static func pinnedHeader(headers: [String: CGRect], contents: [String: CGRect], visibleRect: CGRect?) -> PinnedDiffHeader? {
        guard let visibleRect, visibleRect.isEmpty == false else { return nil }
        let top = visibleRect.minY
        let above = headers.filter { $0.value.isEmpty == false && $0.value.minY < top }
        guard let pinned = above.max(by: { $0.value.minY < $1.value.minY }) else { return nil }
        let frame = pinned.value
        let nextTop = headers.values.filter { $0.minY > frame.minY }.map(\.minY).min()
        let contentEnd = contents[pinned.key].map { $0.isEmpty ? frame.maxY : $0.maxY } ?? frame.maxY
        let end = nextTop ?? contentEnd
        guard end > top else { return nil }
        return PinnedDiffHeader(id: pinned.key, frame: frame, offset: min(0, end - top - frame.height))
    }

    static func estimatedHeight(of model: DiffModel, fontSize: CGFloat) -> CGFloat {
        var lineCount = 1
        if case .lines(let lines, _) = model {
            lineCount = max(lines.count, 1)
        }
        return CGFloat(lineCount) * (fontSize * lineHeightFactor + linePadding) + framePadding
    }
}
