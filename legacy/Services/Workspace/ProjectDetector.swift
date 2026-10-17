import Foundation

nonisolated protocol ProjectDetecting: Sendable {
    func detect(path: String) async -> ProjectDetection
}

nonisolated struct MockProjectDetector: ProjectDetecting {
    func detect(path: String) async -> ProjectDetection {
        ProjectDetection(
            container: "ExampleApp.xcworkspace",
            containerKind: .workspace,
            schemes: ["ExampleApp", "ExampleWidget"],
            bundleID: "com.example.app",
            kind: .xcode,
            isGitRepository: true,
            baseBranch: "origin/main"
        )
    }
}

nonisolated struct LiveProjectDetector: ProjectDetecting {
    let shell: ShellRunner

    func detect(path: String) async -> ProjectDetection {
        var detection = await offMain { Self.scan(path: path) }
        if detection.isGitRepository {
            detection.baseBranch = await baseBranch(at: path)
        }
        return detection
    }

    private func baseBranch(at path: String) async -> String? {
        guard let result = try? await shell.run("git", ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], cwd: path), result.exitCode == 0 else {
            return nil
        }
        let name = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    private static func scan(path: String) -> ProjectDetection {
        let manager = FileManager.default
        let names = ((try? manager.contentsOfDirectory(atPath: path)) ?? []).filter { $0.hasPrefix(".") == false }.sorted()
        let workspace = names.first { $0.hasSuffix(".xcworkspace") }
        let project = names.first { $0.hasSuffix(".xcodeproj") }
        let container = workspace ?? project
        let projectFolders = projectFolders(path: path, workspace: workspace, project: project, siblings: names.filter { $0.hasSuffix(".xcodeproj") })
        let schemeFolders = (container.map { [path + "/" + $0] } ?? []) + projectFolders
        return ProjectDetection(
            container: container,
            containerKind: workspace != nil ? .workspace : (project != nil ? .project : nil),
            schemes: schemes(in: schemeFolders),
            bundleID: bundleID(in: projectFolders),
            kind: container == nil ? .command : .xcode,
            isGitRepository: manager.fileExists(atPath: path + "/.git"),
            baseBranch: nil
        )
    }

    static func projectFolders(path: String, workspace: String?, project: String?, siblings: [String]) -> [String] {
        var folders: [String] = []
        if let workspace {
            let data = (try? String(contentsOfFile: "\(path)/\(workspace)/contents.xcworkspacedata", encoding: .utf8)) ?? ""
            let referenced = XcodeProjectParser.referencedProjects(inWorkspaceData: data).filter { $0.hasPrefix("Pods/") == false }
            folders += referenced.map { path + "/" + $0 }
            folders += siblings.map { path + "/" + $0 }
        } else if let project {
            folders.append(path + "/" + project)
        }
        var seen = Set<String>()
        return folders.filter { seen.insert($0).inserted }
    }

    private static func schemes(in folders: [String]) -> [String] {
        var names = Set<String>()
        for folder in folders {
            let files = (try? FileManager.default.contentsOfDirectory(atPath: folder + "/xcshareddata/xcschemes")) ?? []
            for file in files where file.hasSuffix(".xcscheme") {
                names.insert(String(file.dropLast(".xcscheme".count)))
            }
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func bundleID(in projectFolders: [String]) -> String? {
        let candidates = projectFolders.compactMap { folder -> String? in
            guard let text = try? String(contentsOfFile: folder + "/project.pbxproj", encoding: .utf8) else { return nil }
            return XcodeProjectParser.bundleID(inPbxproj: text)
        }
        return candidates.min { $0.count < $1.count }
    }
}
