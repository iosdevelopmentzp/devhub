import CoreGraphics
import Foundation
import Testing
@testable import DevHubData

@Suite struct FramedVideoCompositionTests {
    private let tablet = try! DeviceChromeParser.chrome(from: Data(DeviceChromeFixture.tablet.utf8))

    @Test func theRenderSizeFitsTheLongSideWithEvenNumbers() {
        let canvas = CGSize(width: 454, height: 908)

        #expect(FramedVideoComposition.renderSize(canvas: canvas, scale: 3, longSide: 1280) == CGSize(width: 640, height: 1280))
        #expect(FramedVideoComposition.renderSize(canvas: canvas, scale: 3, longSide: 1920) == CGSize(width: 960, height: 1920))
        #expect(FramedVideoComposition.renderSize(canvas: CGSize(width: 121, height: 221), scale: 1, longSide: 1280) == CGSize(width: 122, height: 222))
    }

    @Test func theRenderSizeNeverGrowsOverThePixelsOfTheDevice() {
        #expect(FramedVideoComposition.renderSize(canvas: CGSize(width: 120, height: 220), scale: 2, longSide: 1280) == CGSize(width: 240, height: 440))
    }

    @Test func theScreenIsMeasuredFromTheTop() {
        let layout = DeviceFrameLayout.make(chrome: tablet, screen: CGSize(width: 820, height: 1180), compositeSize: nil)

        let screen = FramedVideoComposition.screenFromTop(layout: layout, renderSize: CGSize(width: 1896, height: 2616))

        #expect(screen == CGRect(x: 118, y: 138, width: 1640, height: 2360))
    }

    @Test func anUprightVideoIsScaledIntoTheScreen() {
        let transform = FramedVideoComposition.transform(
            naturalSize: CGSize(width: 1206, height: 2622),
            preferredTransform: .identity,
            into: CGRect(x: 52, y: 34, width: 603, height: 1311)
        )

        #expect(CGPoint.zero.applying(transform) == CGPoint(x: 52, y: 34))
        #expect(CGPoint(x: 1206, y: 2622).applying(transform) == CGPoint(x: 655, y: 1345))
    }

    @Test func aRotatedVideoIsTurnedBeforeItIsScaled() {
        let rotation = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 1206, ty: 0)

        let transform = FramedVideoComposition.transform(
            naturalSize: CGSize(width: 2622, height: 1206),
            preferredTransform: rotation,
            into: CGRect(x: 0, y: 0, width: 603, height: 1311)
        )

        #expect(CGPoint.zero.applying(transform) == CGPoint(x: 603, y: 0))
        #expect(CGPoint(x: 2622, y: 1206).applying(transform) == CGPoint(x: 0, y: 1311))
    }
}
