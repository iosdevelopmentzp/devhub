import Foundation
import DevHubDomain

struct XcodeTestRepository: TestRunRepository {
    let shell: ShellRunner
    let resultsFolder: URL

    static let keptResultBundles = 10

    init(shell: ShellRunner, resultsFolder: URL) {
        self.shell = shell
        self.resultsFolder = resultsFolder
    }

    func run(_ request: TestRunRequest, onEvent: @escaping @Sendable (TestEvent) -> Void) async throws -> TestRunReport {
        let container = try XcodeContainer.locate(in: request.projectPath, preferred: request.container)
        let cwd = (request.projectPath as NSString).expandingTildeInPath
        let bundle = resultBundlePath(for: request)
        try? FileManager.default.createDirectory(at: resultsFolder, withIntermediateDirectories: true)
        let collector = TestOutputCollector(locator: SourceFileLocator(root: cwd))
        let arguments = Self.arguments(container: container.xcodebuildArguments, request: request, resultBundlePath: bundle)
        let exitCode = try await shell.stream("xcodebuild", arguments, cwd: cwd) { line in
            onEvent(.output(line))
            if let parsed = TestOutputParser.parse(line) {
                switch parsed {
                case .runStarted:
                    onEvent(.step("Running tests"))
                case .testFinished(let result):
                    collector.countTest()
                    onEvent(.testFinished(result))
                case .failure(let failure):
                    onEvent(.failure(collector.resolved(failure)))
                }
                return
            }
            if let step = BuildOutputParser.step(from: line), collector.shouldEmitStep(at: .now) {
                onEvent(.step(step))
            }
            if let issue = BuildOutputParser.issue(from: line) {
                onEvent(.issue(issue))
                if issue.severity == .error {
                    collector.addError(issue.message)
                }
            }
        }
        try Task.checkCancellation()
        pruneResultBundles()
        let bundlePath = FileManager.default.fileExists(atPath: bundle) ? bundle : nil
        guard exitCode != 0 else { return TestRunReport(status: .passed, resultBundlePath: bundlePath) }
        guard collector.testCount > 0 else {
            throw TestRunError.failed(collector.firstError ?? "xcodebuild exited with code \(exitCode).")
        }
        return TestRunReport(status: .failed, resultBundlePath: bundlePath)
    }

    static func arguments(container: [String], request: TestRunRequest, resultBundlePath: String) -> [String] {
        container + [
            "-scheme", request.scheme,
            "-configuration", request.configuration,
            "-destination", "id=\(request.simulatorUDID)",
            "-resultBundlePath", resultBundlePath,
        ]
            + request.onlyTests.map { "-only-testing:\($0)" }
            + ["test"]
    }

    func results(bundlePath: String, projectPath: String) async throws -> [TestResultCase] {
        let result = try await shell.run("xcrun", Self.resultsArguments(bundlePath: bundlePath), cwd: nil)
        guard result.exitCode == 0 else { throw TestRunError.failed(result.failureMessage) }
        let locator = SourceFileLocator(root: projectPath)
        return try XcresultParser.cases(from: Data(result.stdout.utf8)).map { item in
            guard item.path == nil, let file = item.file else { return item }
            var resolved = item
            resolved.path = locator.path(forFileName: file)
            return resolved
        }
    }

    func exportAttachments(bundlePath: String) async throws -> [TestAttachment] {
        let folder = attachmentsFolder(forBundle: bundlePath)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let result = try await shell.run("xcrun", Self.exportArguments(bundlePath: bundlePath, folder: folder.path), cwd: nil)
        guard result.exitCode == 0 else { throw TestRunError.failed(result.failureMessage) }
        let manifest = try Data(contentsOf: folder.appendingPathComponent("manifest.json"))
        return try XcresultAttachmentParser.attachments(from: manifest, folder: folder)
    }

    static func resultsArguments(bundlePath: String) -> [String] {
        ["xcresulttool", "get", "test-results", "tests", "--path", bundlePath]
    }

    static func exportArguments(bundlePath: String, folder: String) -> [String] {
        ["xcresulttool", "export", "attachments", "--path", bundlePath, "--output-path", folder]
    }

    func attachmentsFolder(forBundle bundlePath: String) -> URL {
        let name = ((bundlePath as NSString).lastPathComponent as NSString).deletingPathExtension
        return resultsFolder.appendingPathComponent("Attachments", isDirectory: true).appendingPathComponent(name, isDirectory: true)
    }

    private func resultBundlePath(for request: TestRunRequest) -> String {
        let stamp = Int(Date.now.timeIntervalSince1970)
        let scheme = request.scheme.replacingOccurrences(of: "/", with: "-")
        return resultsFolder.appendingPathComponent("\(scheme)-\(stamp).xcresult").path
    }

    private func pruneResultBundles() {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        let bundles = ((try? FileManager.default.contentsOfDirectory(at: resultsFolder, includingPropertiesForKeys: keys)) ?? [])
            .filter { $0.pathExtension == "xcresult" }
            .sorted { modificationDate($0) > modificationDate($1) }
        for stale in bundles.dropFirst(Self.keptResultBundles) {
            try? FileManager.default.removeItem(at: stale)
            try? FileManager.default.removeItem(at: attachmentsFolder(forBundle: stale.path))
        }
    }

    private func modificationDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}

private nonisolated final class TestOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private let locator: SourceFileLocator
    private var errors: [String] = []
    private var tests = 0
    private var stepThrottle = BuildStepThrottle(interval: .milliseconds(200))

    init(locator: SourceFileLocator) {
        self.locator = locator
    }

    var firstError: String? {
        lock.withLock { errors.first }
    }

    var testCount: Int {
        lock.withLock { tests }
    }

    func countTest() {
        lock.withLock { tests += 1 }
    }

    func addError(_ message: String) {
        lock.withLock { errors.append(message) }
    }

    func shouldEmitStep(at now: ContinuousClock.Instant) -> Bool {
        lock.withLock { stepThrottle.shouldEmit(at: now) }
    }

    func resolved(_ failure: TestFailure) -> TestFailure {
        guard failure.path == nil, let file = failure.file else { return failure }
        var resolved = failure
        resolved.path = locator.path(forFileName: file)
        return resolved
    }
}
