import Foundation
import DevHubDomain

struct XcodeBuildRepository: BuildRepository {
    let shell: ShellRunner
    let productLocator: ProductLocator

    init(shell: ShellRunner, productLocator: ProductLocator) {
        self.shell = shell
        self.productLocator = productLocator
    }

    func schemes(projectPath: String, container: String?) async -> [String] {
        guard let container = try? XcodeContainer.locate(in: projectPath, preferred: container) else { return [] }
        return container.schemeNames()
    }

    func lastBuiltAppPath(projectPath: String, container: String?, scheme: String, configuration: String) -> String? {
        guard let container = try? XcodeContainer.locate(in: projectPath, preferred: container) else { return nil }
        return productLocator.appPath(hints: [], container: container, scheme: scheme, configuration: configuration)
    }

    func product(atAppPath path: String) throws -> BuildProduct {
        let expanded = (path as NSString).expandingTildeInPath
        guard let bundleID = productLocator.bundleID(ofApp: expanded) else { throw BuildError.appNotFound }
        return BuildProduct(appPath: expanded, bundleID: bundleID)
    }

    func clean(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws {
        let invocation = try Invocation(request)
        try await xcodebuild(invocation.common + ["clean"], cwd: invocation.cwd, onEvent: onEvent)
    }

    func build(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws -> [String] {
        let invocation = try Invocation(request)
        return try await xcodebuild(invocation.common + ["ONLY_ACTIVE_ARCH=YES", "build"], cwd: invocation.cwd, onEvent: onEvent)
    }

    func locateProduct(_ request: BuildRequest, hints: [String]) async throws -> BuildProduct {
        let invocation = try Invocation(request)
        let appPath: String
        if let located = productLocator.appPath(hints: hints, container: invocation.container, scheme: request.scheme, configuration: request.configuration) {
            appPath = located
        } else {
            appPath = try await appPathFromBuildSettings(invocation.common, cwd: invocation.cwd)
        }
        guard let bundleID = productLocator.bundleID(ofApp: appPath) else { throw BuildError.appNotFound }
        return BuildProduct(appPath: appPath, bundleID: bundleID)
    }

    @discardableResult
    private func xcodebuild(
        _ arguments: [String],
        cwd: String,
        onEvent: @escaping @Sendable (BuildEvent) -> Void
    ) async throws -> [String] {
        let collector = BuildOutputCollector()
        let exitCode = try await shell.stream("xcodebuild", arguments, cwd: cwd) { line in
            onEvent(.output(line))
            if let step = BuildOutputParser.step(from: line), collector.shouldEmitStep(at: .now) {
                onEvent(.step(step, progress: nil))
            }
            if let error = BuildOutputParser.error(from: line) {
                collector.addError(error)
            }
            if let appPath = BuildOutputParser.appPath(from: line) {
                collector.addAppPath(appPath)
            }
        }
        try Task.checkCancellation()
        guard exitCode == 0 else {
            throw BuildError.failed(collector.firstError ?? "xcodebuild exited with code \(exitCode).")
        }
        return collector.appPaths
    }

    private func appPathFromBuildSettings(_ common: [String], cwd: String) async throws -> String {
        let result = try await shell.run("xcodebuild", common + ["-showBuildSettings", "-json"], cwd: cwd)
        guard result.exitCode == 0 else { throw BuildError.failed(result.stderr.trimmed) }
        guard
            let entries = try? JSONSerialization.jsonObject(with: Data(result.stdout.utf8)) as? [[String: Any]],
            let settings = entries
                .compactMap({ $0["buildSettings"] as? [String: Any] })
                .first(where: { $0["PRODUCT_TYPE"] as? String == "com.apple.product-type.application" }),
            let directory = settings["TARGET_BUILD_DIR"] as? String,
            let wrapper = settings["WRAPPER_NAME"] as? String
        else {
            throw BuildError.appNotFound
        }
        return (directory as NSString).appendingPathComponent(wrapper)
    }
}

private nonisolated struct Invocation {
    let container: XcodeContainer
    let cwd: String
    let common: [String]

    init(_ request: BuildRequest) throws {
        container = try XcodeContainer.locate(in: request.projectPath, preferred: request.container)
        cwd = (request.projectPath as NSString).expandingTildeInPath
        common = container.xcodebuildArguments + [
            "-scheme", request.scheme,
            "-configuration", request.configuration,
            "-destination", "id=\(request.simulatorUDID)"
        ]
    }
}

private nonisolated final class BuildOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var errors: [String] = []
    private var paths: [String] = []
    private var stepThrottle = BuildStepThrottle(interval: .milliseconds(200))

    var firstError: String? {
        lock.withLock { errors.first }
    }

    var appPaths: [String] {
        lock.withLock { paths }
    }

    func shouldEmitStep(at now: ContinuousClock.Instant) -> Bool {
        lock.withLock { stepThrottle.shouldEmit(at: now) }
    }

    func addError(_ message: String) {
        lock.withLock { errors.append(message) }
    }

    func addAppPath(_ path: String) {
        lock.withLock {
            guard paths.contains(path) == false else { return }
            paths.append(path)
        }
    }
}
