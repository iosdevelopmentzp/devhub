import Foundation
import DevHubDomain

struct XcodeContainer {
    enum Kind {
        case workspace
        case project
    }

    let kind: Kind
    let url: URL

    var xcodebuildArguments: [String] {
        switch kind {
        case .workspace: ["-workspace", url.path]
        case .project: ["-project", url.path]
        }
    }

    static func locate(in folder: String) throws -> XcodeContainer {
        let root = URL(fileURLWithPath: (folder as NSString).expandingTildeInPath)
        let entries = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        if let workspace = entries.first(where: { $0.pathExtension == "xcworkspace" }) {
            return XcodeContainer(kind: .workspace, url: workspace)
        }
        if let project = entries.first(where: { $0.pathExtension == "xcodeproj" }) {
            return XcodeContainer(kind: .project, url: project)
        }
        throw BuildError.noXcodeContainer(folder)
    }

    func schemeNames() -> [String] {
        var roots = [url]
        if kind == .workspace {
            let siblings = (try? FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil)) ?? []
            roots += siblings.filter { $0.pathExtension == "xcodeproj" }
        }
        var names: Set<String> = []
        for root in roots {
            names.formUnion(schemeFiles(in: root.appendingPathComponent("xcshareddata/xcschemes")))
            let userData = root.appendingPathComponent("xcuserdata")
            let users = (try? FileManager.default.contentsOfDirectory(at: userData, includingPropertiesForKeys: nil)) ?? []
            for user in users {
                names.formUnion(schemeFiles(in: user.appendingPathComponent("xcschemes")))
            }
        }
        return names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private func schemeFiles(in directory: URL) -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "xcscheme" }.map { $0.deletingPathExtension().lastPathComponent }
    }
}
