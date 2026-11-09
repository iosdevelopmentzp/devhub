import CoreGraphics
import Foundation
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct DiffViewportPolicyTests {
    private let visible = CGRect(x: 0, y: 1_000, width: 800, height: 600)

    @Test func unknownViewportKeepsEveryDiff() {
        let far = CGRect(x: 0, y: 9_000, width: 800, height: 100)

        #expect(DiffViewportPolicy.isNear(far, visibleRect: nil))
        #expect(DiffViewportPolicy.isNear(far, visibleRect: .zero))
    }

    @Test func unmeasuredFrameWaitsForItsLayout() {
        #expect(DiffViewportPolicy.isNear(.zero, visibleRect: visible) == false)
    }

    @Test func framesWithinOneViewportHeightAreNear() {
        #expect(DiffViewportPolicy.isNear(CGRect(x: 0, y: 1_200, width: 800, height: 100), visibleRect: visible))
        #expect(DiffViewportPolicy.isNear(CGRect(x: 0, y: 2_100, width: 800, height: 100), visibleRect: visible))
        #expect(DiffViewportPolicy.isNear(CGRect(x: 0, y: 500, width: 800, height: 100), visibleRect: visible))
    }

    @Test func framesFartherThanOneViewportHeightAreFar() {
        #expect(DiffViewportPolicy.isNear(CGRect(x: 0, y: 2_300, width: 800, height: 100), visibleRect: visible) == false)
        #expect(DiffViewportPolicy.isNear(CGRect(x: 0, y: 200, width: 800, height: 100), visibleRect: visible) == false)
    }

    @Test func nearIDsKeepTheFramesAroundTheViewport() {
        let frames = [
            "near": CGRect(x: 0, y: 1_200, width: 800, height: 100),
            "far": CGRect(x: 0, y: 5_000, width: 800, height: 100),
            "unmeasured": CGRect.zero,
        ]

        #expect(DiffViewportPolicy.nearIDs(frames: frames, visibleRect: visible) == ["near"])
        #expect(DiffViewportPolicy.nearIDs(frames: frames, visibleRect: nil) == ["near", "far", "unmeasured"])
        #expect(DiffViewportPolicy.nearIDs(frames: [:], visibleRect: visible).isEmpty)
    }

    @Test func estimatedHeightGrowsWithLinesAndFontSize() {
        let short = DiffModel.lines([.preview], droppedNote: nil)
        let long = DiffModel.lines(Array(repeating: .preview, count: 10), droppedNote: nil)

        #expect(DiffViewportPolicy.estimatedHeight(of: long, fontSize: 11) > DiffViewportPolicy.estimatedHeight(of: short, fontSize: 11))
        #expect(DiffViewportPolicy.estimatedHeight(of: long, fontSize: 14) > DiffViewportPolicy.estimatedHeight(of: long, fontSize: 11))
        #expect(DiffViewportPolicy.estimatedHeight(of: .note("Binary"), fontSize: 11) == DiffViewportPolicy.estimatedHeight(of: short, fontSize: 11))
    }
}
