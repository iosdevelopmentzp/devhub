import CoreGraphics
import Foundation
import Testing
@testable import DevHubData

@Suite struct DeviceFrameLayoutTests {
    private let phone = try! DeviceChromeParser.chrome(from: Data(DeviceChromeFixture.phone.utf8))
    private let tablet = try! DeviceChromeParser.chrome(from: Data(DeviceChromeFixture.tablet.utf8))

    @Test func aCompositeCentersTheScreenAndAddsThePadding() {
        let layout = DeviceFrameLayout.make(chrome: phone, screen: CGSize(width: 402, height: 874), compositeSize: CGSize(width: 436, height: 908))

        #expect(layout.canvas == CGSize(width: 454, height: 908))
        #expect(layout.body == CGRect(x: 9, y: 0, width: 436, height: 908))
        #expect(layout.screen == CGRect(x: 26, y: 17, width: 402, height: 874))
    }

    @Test func piecesSurroundTheScreenWithTheSizing() {
        let layout = DeviceFrameLayout.make(chrome: tablet, screen: CGSize(width: 820, height: 1180), compositeSize: nil)

        #expect(layout.canvas == CGSize(width: 948, height: 1308))
        #expect(layout.body == CGRect(x: 0, y: 0, width: 938, height: 1298))
        #expect(layout.screen == CGRect(x: 59, y: 59, width: 820, height: 1180))
    }

    @Test func sideButtonsStickOutOfTheirEdge() {
        let layout = DeviceFrameLayout.make(chrome: phone, screen: CGSize(width: 402, height: 874), compositeSize: CGSize(width: 436, height: 908))

        #expect(layout.rect(of: phone.buttons[0], size: CGSize(width: 16, height: 34)) == CGRect(x: 1, y: 714, width: 16, height: 34))
        #expect(layout.rect(of: phone.buttons[1], size: CGSize(width: 16, height: 101)) == CGRect(x: 437, y: 545, width: 16, height: 101))
    }

    @Test func aTopTrailingButtonCountsFromTheRightEdge() {
        let layout = DeviceFrameLayout.make(chrome: tablet, screen: CGSize(width: 820, height: 1180), compositeSize: nil)

        #expect(layout.rect(of: tablet.buttons[0], size: CGSize(width: 89, height: 16)) == CGRect(x: 765, y: 1290, width: 89, height: 16))
    }
}
