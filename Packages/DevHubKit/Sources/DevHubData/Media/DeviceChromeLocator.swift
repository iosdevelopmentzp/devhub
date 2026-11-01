import Foundation
import CoreGraphics
import DevHubDomain

struct DeviceChromeLocator: Sendable {
    let devicesRoot: URL
    let deviceTypeRoots: [URL]
    let chromeRoot: URL

    func source(udid: String) throws -> DeviceFrameSource {
        guard let deviceType = PlistReader.dictionary(at: devicesRoot.appendingPathComponent("\(udid)/device.plist"))?["deviceType"] as? String else {
            throw MediaError.noFrame("DevHub cannot read the device type of this simulator.")
        }
        guard let profile = profile(of: deviceType) else {
            throw MediaError.noFrame("Xcode has no profile for \(deviceType).")
        }
        guard let chromeID = profile["chromeIdentifier"] as? String,
              let width = profile["mainScreenWidth"] as? Double,
              let height = profile["mainScreenHeight"] as? Double,
              let scale = profile["mainScreenScale"] as? Double, scale > 0 else {
            throw MediaError.noFrame("the profile of \(deviceType) has no frame or screen size.")
        }
        let name = chromeID.split(separator: ".").last.map(String.init) ?? chromeID
        let folder = chromeRoot.appendingPathComponent("\(name).devicechrome/Contents/Resources", isDirectory: true)
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("chrome.json")) else {
            throw MediaError.noFrame("Xcode has no frame \(name).")
        }
        guard let chrome = try? DeviceChromeParser.chrome(from: data) else {
            throw MediaError.noFrame("the frame \(name) has an unknown format.")
        }
        return DeviceFrameSource(folder: folder, chrome: chrome, screen: CGSize(width: width / scale, height: height / scale), scale: scale)
    }

    private func profile(of deviceType: String) -> [String: Any]? {
        for root in deviceTypeRoots {
            let bundles = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
            for bundle in bundles where bundle.pathExtension == "simdevicetype" {
                guard PlistReader.dictionary(at: bundle.appendingPathComponent("Contents/Info.plist"))?["CFBundleIdentifier"] as? String == deviceType else { continue }
                return PlistReader.dictionary(at: bundle.appendingPathComponent("Contents/Resources/profile.plist"))
            }
        }
        return nil
    }
}
