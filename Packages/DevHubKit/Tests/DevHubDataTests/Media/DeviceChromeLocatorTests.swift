import CoreGraphics
import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct DeviceChromeLocatorTests {
    private let tree: DeviceChromeTree

    init() throws {
        tree = DeviceChromeTree(directory: try TemporaryDirectory())
    }

    @Test func theDeviceTypeLeadsToTheFrameAndTheScreenSize() throws {
        try tree.makeDevice()
        try tree.makeChrome()

        let source = try tree.locator.source(udid: DeviceChromeTree.udid)

        #expect(source.screen == CGSize(width: 100, height: 200))
        #expect(source.scale == 2)
        #expect(source.chrome.composite == "Composite")
        #expect(source.folder.path.hasSuffix("Chrome/phonex.devicechrome/Contents/Resources"))
    }

    @Test func anUnknownSimulatorHasNoFrame() {
        #expect(throws: MediaError.self) {
            try tree.locator.source(udid: "OTHER")
        }
    }

    @Test func aMissingFrameFolderIsReported() throws {
        try tree.makeDevice()

        #expect {
            try tree.locator.source(udid: DeviceChromeTree.udid)
        } throws: { error in
            error.localizedDescription == "No device frame: Xcode has no frame phonex."
        }
    }
}
