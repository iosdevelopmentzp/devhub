import Foundation
import DevHubDomain

struct ProductLocator {
    let derivedData: XcodeDerivedDataRepository

    func appPath(hints: [String], container: XcodeContainer, scheme: String, configuration: String, isPhysicalDevice: Bool = false) -> String? {
        let productsSuffix = "\(Self.productsFolder(configuration: configuration, isPhysicalDevice: isPhysicalDevice))/"
        if let hinted = hints.first(where: { $0.contains(productsSuffix) && FileManager.default.fileExists(atPath: $0) }) {
            return hinted
        }
        guard let productsDirectory = derivedDataProducts(for: container, configuration: configuration, isPhysicalDevice: isPhysicalDevice) else { return nil }
        let apps = ((try? FileManager.default.contentsOfDirectory(at: productsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [])
            .filter { $0.pathExtension == "app" }
        if let named = apps.first(where: { $0.deletingPathExtension().lastPathComponent == scheme }) {
            return named.path
        }
        if apps.count == 1, let only = apps.first {
            return only.path
        }
        return apps
            .max { FileManager.default.modificationDate(of: $0) < FileManager.default.modificationDate(of: $1) }?
            .path
    }

    func bundleID(ofApp appPath: String) -> String? {
        PlistReader.dictionary(at: URL(fileURLWithPath: appPath).appendingPathComponent("Info.plist"))?["CFBundleIdentifier"] as? String
    }

    static func productsFolder(configuration: String, isPhysicalDevice: Bool) -> String {
        "\(configuration)-\(isPhysicalDevice ? "iphoneos" : "iphonesimulator")"
    }

    private func derivedDataProducts(for container: XcodeContainer, configuration: String, isPhysicalDevice: Bool) -> URL? {
        derivedData.folder(forContainer: container.url)?.appendingPathComponent("Build/Products/\(Self.productsFolder(configuration: configuration, isPhysicalDevice: isPhysicalDevice))")
    }
}
