import Foundation
import DevHubDomain

enum ExampleConfigWriter {
    static func write(_ files: [ExampleFile], into folder: String) throws {
        let manager = FileManager.default
        guard manager.fileExists(atPath: folder) == false else {
            throw ConfigError.exampleExists(folder)
        }
        for file in files {
            let path = folder + "/" + file.path
            try manager.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try (file.text + "\n").write(toFile: path, atomically: true, encoding: .utf8)
            if file.isExecutable {
                try manager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
            }
        }
    }
}
