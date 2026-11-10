import Foundation
import Observation

@Observable
final class DiffViewport {
    private(set) var nearIDs: Set<String> = []
    private(set) var pinnedHeader: PinnedDiffHeader?

    @ObservationIgnored private var frames: [String: CGRect] = [:]
    @ObservationIgnored private var headerFrames: [String: CGRect] = [:]
    @ObservationIgnored private var visibleRect: CGRect?

    static let coordinateSpace = "diffViewport"

    func update(visibleRect: CGRect) {
        self.visibleRect = visibleRect
        recompute()
    }

    func update(frame: CGRect, of id: String) {
        frames[id] = frame
        recompute()
    }

    func forget(_ id: String) {
        frames[id] = nil
        recompute()
    }

    func update(headerFrame: CGRect, of id: String) {
        headerFrames[id] = headerFrame
        recompute()
    }

    func forgetHeader(_ id: String) {
        headerFrames[id] = nil
        recompute()
    }

    private func recompute() {
        let near = DiffViewportPolicy.nearIDs(frames: frames, visibleRect: visibleRect)
        if near != nearIDs {
            nearIDs = near
        }
        let pinned = DiffViewportPolicy.pinnedHeader(headers: headerFrames, contents: frames, visibleRect: visibleRect)
        if pinned != pinnedHeader {
            pinnedHeader = pinned
        }
    }
}
