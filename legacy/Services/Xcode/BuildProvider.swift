import Foundation

nonisolated struct BuildRequest: Hashable, Sendable {
    var container: String
    var scheme: String
    var configuration: String
    var simulatorID: String
    var folder: String

    var containerArguments: [String] {
        [container.hasSuffix(".xcworkspace") ? "-workspace" : "-project", container]
    }
}

nonisolated enum BuildOutput: Sendable {
    case line(String)
    case finished(Int32)
}

nonisolated struct BuildError: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? { message }
}

nonisolated protocol BuildProviding: Sendable {
    func configurations(container: String) async -> [String]
    func xcodebuild(_ request: BuildRequest, action: String) -> AsyncThrowingStream<BuildOutput, Error>
    func command(executable: String, folder: String, environment: [String: String]) -> AsyncThrowingStream<BuildOutput, Error>
    func locateApp(_ request: BuildRequest, outputPath: String?) async throws -> String
    func bundleID(appPath: String) async throws -> String
    func cacheApp(_ appPath: String, simulatorID: String, bundleID: String) async throws
    func cachedApp(simulatorID: String, bundleID: String) async -> String?
    func writeLog(_ lines: [String]) async throws -> String
    func showLog(at path: String) async throws
}

nonisolated struct MockBuildProvider: BuildProviding {
    func configurations(container: String) async -> [String] { ["Debug", "Release"] }

    func xcodebuild(_ request: BuildRequest, action: String) -> AsyncThrowingStream<BuildOutput, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.finished(0))
            continuation.finish()
        }
    }

    func command(executable: String, folder: String, environment: [String: String]) -> AsyncThrowingStream<BuildOutput, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.finished(0))
            continuation.finish()
        }
    }

    func locateApp(_ request: BuildRequest, outputPath: String?) async throws -> String { "/tmp/Sample.app" }
    func bundleID(appPath: String) async throws -> String { "com.example.sample" }
    func cacheApp(_ appPath: String, simulatorID: String, bundleID: String) async throws {}
    func cachedApp(simulatorID: String, bundleID: String) async -> String? { nil }
    func writeLog(_ lines: [String]) async throws -> String { "/tmp/build.log" }
    func showLog(at path: String) async throws {}
}
