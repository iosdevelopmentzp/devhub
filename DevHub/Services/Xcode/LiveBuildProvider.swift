import Foundation

nonisolated struct LiveBuildProvider: BuildProviding {
    let shell: ShellRunner
    let home: String

    func configurations(container: String) async -> [String] {
        await offMain { Self.readConfigurations(container: container) }
    }

    func xcodebuild(_ request: BuildRequest, action: String) -> AsyncThrowingStream<BuildOutput, Error> {
        let arguments = request.containerArguments + [
            "-scheme", request.scheme,
            "-configuration", request.configuration,
            "-destination", "id=\(request.simulatorID)",
            "ONLY_ACTIVE_ARCH=YES",
            action
        ]
        return stream("xcodebuild", arguments, folder: request.folder, environment: [:])
    }

    func command(executable: String, folder: String, environment: [String: String]) -> AsyncThrowingStream<BuildOutput, Error> {
        stream(executable, [], folder: folder, environment: environment)
    }

    func locateApp(_ request: BuildRequest, outputPath: String?) async throws -> String {
        if let outputPath, FileManager.default.fileExists(atPath: outputPath) {
            return outputPath
        }
        if let found = await derivedDataApp(request) {
            return found
        }
        return try await appFromBuildSettings(request)
    }

    func bundleID(appPath: String) async throws -> String {
        let data = await offMain { FileManager.default.contents(atPath: appPath + "/Info.plist") }
        guard let data,
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let identifier = plist["CFBundleIdentifier"] as? String else {
            throw BuildError(message: "The built app has no bundle ID in its Info.plist.")
        }
        return identifier
    }

    func cacheApp(_ appPath: String, simulatorID: String, bundleID: String) async throws {
        let folder = home + "/Library/Caches/DevHub/Apps"
        let target = "\(folder)/\(simulatorID)-\(bundleID).app"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(atPath: target)
        let result = try await shell.run("ditto", [appPath, target], cwd: nil)
        guard result.exitCode == 0 else {
            throw BuildError(message: result.failureMessage)
        }
    }

    func cachedApp(simulatorID: String, bundleID: String) async -> String? {
        let path = "\(home)/Library/Caches/DevHub/Apps/\(simulatorID)-\(bundleID).app"
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    func writeLog(_ lines: [String]) async throws -> String {
        let stamp = Int(Date().timeIntervalSince1970)
        let path = NSTemporaryDirectory() + "devhub-build-\(stamp).log"
        let text = lines.joined(separator: "\n")
        let written = await offMain { (try? text.write(toFile: path, atomically: true, encoding: .utf8)) != nil }
        guard written else {
            throw BuildError(message: "The build log could not be written to \(path).")
        }
        return path
    }

    func showLog(at path: String) async throws {
        let result = try await shell.run("open", ["-a", "Console", path], cwd: nil)
        guard result.exitCode == 0 else {
            throw BuildError(message: result.failureMessage)
        }
    }

    private func stream(_ executable: String, _ arguments: [String], folder: String, environment: [String: String]) -> AsyncThrowingStream<BuildOutput, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [shell] in
                do {
                    let code = try await shell.stream(executable, arguments, cwd: folder, environment: environment) { line in
                        continuation.yield(.line(line))
                    }
                    continuation.yield(.finished(code))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func derivedDataApp(_ request: BuildRequest) async -> String? {
        await offMain {
            let root = LiveWorktreeProvider.derivedDataRoot()
            let target = Self.normalized(request.container)
            let matches = LiveWorktreeProvider.workspaceFolders(root: root).filter { Self.normalized($0.workspace) == target }
            let products = matches.flatMap { Self.apps(in: $0.path + "/Build/Products/\(request.configuration)-iphonesimulator") }
            return Self.bestApp(products, scheme: request.scheme)
        }
    }

    private func appFromBuildSettings(_ request: BuildRequest) async throws -> String {
        let arguments = request.containerArguments + [
            "-scheme", request.scheme,
            "-configuration", request.configuration,
            "-destination", "id=\(request.simulatorID)",
            "-showBuildSettings", "-json"
        ]
        let result = try await shell.run("xcodebuild", arguments, cwd: request.folder)
        guard result.exitCode == 0, let path = Self.applicationPath(inBuildSettings: Data(result.stdout.utf8)) else {
            throw BuildError(message: "The build finished but the app could not be found.")
        }
        return path
    }

    private static func readConfigurations(container: String) -> [String] {
        let manager = FileManager.default
        let folder = (container as NSString).deletingLastPathComponent
        let names = ((try? manager.contentsOfDirectory(atPath: folder)) ?? []).filter { $0.hasSuffix(".xcodeproj") }
        let isWorkspace = container.hasSuffix(".xcworkspace")
        let projects = LiveProjectDetector.projectFolders(
            path: folder,
            workspace: isWorkspace ? (container as NSString).lastPathComponent : nil,
            project: isWorkspace ? nil : (container as NSString).lastPathComponent,
            siblings: names
        )
        var found: [String] = []
        for project in projects {
            guard let text = try? String(contentsOfFile: project + "/project.pbxproj", encoding: .utf8) else { continue }
            for name in XcodeProjectParser.configurationNames(inPbxproj: text) where found.contains(name) == false {
                found.append(name)
            }
        }
        return found
    }

    private static func normalized(_ path: String) -> String {
        var standard = (path as NSString).standardizingPath
        if standard.hasPrefix("/private/") {
            standard = String(standard.dropFirst("/private".count))
        }
        return standard.lowercased()
    }

    private static func apps(in folder: String) -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return names.filter { $0.hasSuffix(".app") }.map { folder + "/" + $0 }
    }

    private static func bestApp(_ apps: [String], scheme: String) -> String? {
        if let named = apps.first(where: { ($0 as NSString).lastPathComponent == scheme + ".app" }) {
            return named
        }
        if apps.count == 1 {
            return apps.first
        }
        return apps.max { modified($0) < modified($1) }
    }

    private static func modified(_ path: String) -> Date {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date ?? .distantPast
    }

    private static func applicationPath(inBuildSettings data: Data) -> String? {
        guard let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return nil }
        for entry in entries {
            guard let settings = entry["buildSettings"] as? [String: String],
                  settings["PRODUCT_TYPE"] == "com.apple.product-type.application",
                  let directory = settings["TARGET_BUILD_DIR"], let wrapper = settings["WRAPPER_NAME"] else { continue }
            return directory + "/" + wrapper
        }
        return nil
    }
}
