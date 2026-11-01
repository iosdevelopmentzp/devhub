import Foundation
import Testing
@testable import DevHubData

@Suite struct DeviceChromeParserTests {
    @Test func aPhoneHasACompositePaddingAndButtons() throws {
        let chrome = try DeviceChromeParser.chrome(from: Data(DeviceChromeFixture.phone.utf8))

        #expect(chrome.composite == "PhoneComposite")
        #expect(chrome.pieces.topLeft == "Phone TL")
        #expect(chrome.pieces.bottom == "Phone Base")
        #expect(chrome.sizing == DeviceChrome.Insets(top: 18, left: 18, bottom: 18, right: 18))
        #expect(chrome.padding == DeviceChrome.Insets(top: 0, left: 9, bottom: 0, right: 9))
        #expect(chrome.buttons == [
            DeviceChrome.Button(image: "Mute BTN", anchor: "left", align: "leading", onTop: false, x: 8, y: 160),
            DeviceChrome.Button(image: "X_Power BTN", anchor: "right", align: "leading", onTop: false, x: -8, y: 262),
        ])
    }

    @Test func aTabletWithoutACompositeUsesItsPieces() throws {
        let chrome = try DeviceChromeParser.chrome(from: Data(DeviceChromeFixture.tablet.utf8))

        #expect(chrome.composite == nil)
        #expect(chrome.padding == DeviceChrome.Insets(top: 10, left: 0, bottom: 0, right: 10))
        #expect(chrome.buttons.first?.anchor == "top")
        #expect(chrome.buttons.first?.align == "trailing")
    }

    @Test func aChromeWithoutPaddingHasNone() throws {
        let chrome = try DeviceChromeParser.chrome(from: Data(DeviceChromeFixture.composite.utf8))

        #expect(chrome.padding == .zero)
        #expect(chrome.buttons.isEmpty)
    }

    @Test func aBrokenFileFails() {
        #expect(throws: (any Error).self) {
            try DeviceChromeParser.chrome(from: Data("{\"images\": {}}".utf8))
        }
    }
}
