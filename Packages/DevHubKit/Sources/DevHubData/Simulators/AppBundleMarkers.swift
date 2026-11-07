import Foundation
import DevHubDomain

struct AppBundleMarkers: Sendable {
    let shell: ShellRunner

    func contains(_ marker: String?, appPath: String, executable: String?) async -> Bool {
        guard let marker, marker.isEmpty == false else { return false }
        let app = URL(fileURLWithPath: appPath)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: appPath)) ?? []
        let candidates = files.filter { $0.hasSuffix(".debug.dylib") } + [executable].compactMap { $0 }
        for name in candidates {
            let result = try? await shell.run("grep", ["-q", "-a", "-F", marker, app.appendingPathComponent(name).path], cwd: nil)
            if result?.exitCode == 0 { return true }
        }
        return false
    }
}
