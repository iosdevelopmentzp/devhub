import Foundation
import Observation

@Observable
final class DiffViewport {
    private(set) var nearIDs: Set<String> = []

    @ObservationIgnored private var frames: [String: CGRect] = [:]
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

    private func recompute() {
        let near = DiffViewportPolicy.nearIDs(frames: frames, visibleRect: visibleRect)
        guard near != nearIDs else { return }
        nearIDs = near
    }
}
