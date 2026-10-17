import DevHubTestSupport
import Foundation

struct SimulatorContainerTree {
    static let udid = "SIM-1"
    static let bundleID = "com.example.app"

    let directory: TemporaryDirectory

    var devicesRoot: URL {
        directory.url
    }

    func makeDataContainer(folder: String, bundleID: String) throws -> String {
        let path = "\(Self.udid)/data/Containers/Data/Application/\(folder)"
        let metadata = try PropertyListSerialization.data(fromPropertyList: ["MCMMetadataIdentifier": bundleID], format: .xml, options: 0)
        let plist = directory.url.appendingPathComponent("\(path)/.com.apple.mobile_container_manager.metadata.plist")
        try FileManager.default.createDirectory(at: plist.deletingLastPathComponent(), withIntermediateDirectories: true)
        try metadata.write(to: plist)
        return directory.path(path)
    }

    @discardableResult
    func writeLog(_ text: String, named name: String, folder: String, modified: Date) throws -> URL {
        let file = try directory.write(text, to: "\(Self.udid)/data/Containers/Data/Application/\(folder)/Library/Application Support/Logs/\(name)")
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: file.path)
        return file
    }
}
