import CoreGraphics
import DevHubTestSupport
import Foundation
@testable import DevHubData

struct DeviceChromeTree {
    static let udid = "SIM-1"
    static let deviceType = "com.example.DeviceType.Phone"

    let directory: TemporaryDirectory

    var locator: DeviceChromeLocator {
        DeviceChromeLocator(
            devicesRoot: directory.url.appendingPathComponent("Devices"),
            deviceTypeRoots: [directory.url.appendingPathComponent("DeviceTypes")],
            chromeRoot: directory.url.appendingPathComponent("Chrome")
        )
    }

    func makeDevice() throws {
        try writePlist(["deviceType": Self.deviceType], to: "Devices/\(Self.udid)/device.plist")
        try writePlist(["CFBundleIdentifier": Self.deviceType], to: "DeviceTypes/Phone.simdevicetype/Contents/Info.plist")
        try writePlist(
            ["chromeIdentifier": "com.example.chrome.phonex", "mainScreenWidth": 200, "mainScreenHeight": 400, "mainScreenScale": 2],
            to: "DeviceTypes/Phone.simdevicetype/Contents/Resources/profile.plist"
        )
    }

    func makeChrome() throws {
        let folder = "Chrome/phonex.devicechrome/Contents/Resources"
        _ = try directory.write(DeviceChromeFixture.composite, to: "\(folder)/chrome.json")
        var box = CGRect(x: 0, y: 0, width: 120, height: 220)
        let url = directory.url.appendingPathComponent("\(folder)/Composite.pdf") as CFURL
        guard let context = CGContext(url, mediaBox: &box, nil) else { throw CocoaError(.fileWriteUnknown) }
        context.beginPDFPage(nil)
        context.setFillColor(CGColor(gray: 0.2, alpha: 1))
        context.fill(box)
        context.endPDFPage()
        context.closePDF()
    }

    private func writePlist(_ values: [String: Any], to path: String) throws {
        let file = directory.url.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0).write(to: file)
    }
}
