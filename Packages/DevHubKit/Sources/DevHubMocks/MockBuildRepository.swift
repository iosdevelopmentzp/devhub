import Foundation
import DevHubDomain

struct MockBuildRepository: BuildRepository {

    func schemes(projectPath: String, container: String?) async -> [String] {
        ["ExampleApp", "ExampleApp Staging", "NotificationServiceExtension"]
    }

    func listedSchemes(projectPath: String, container: String?) async throws -> [String] {
        ["ExampleApp", "ExampleApp Staging", "ExampleWidget", "NotificationServiceExtension"]
    }

    func product(atAppPath path: String) throws -> BuildProduct {
        BuildProduct(appPath: path, bundleID: "com.example.app")
    }

    func lastBuiltAppPath(projectPath: String, container: String?, scheme: String, configuration: String, isPhysicalDevice: Bool) -> String? {
        nil
    }

    func clean(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func build(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws -> [String] {
        let steps = [
            "Resolving packages",
            "Compiling \(request.scheme)",
            "Linking",
            "Installing on \(request.simulatorName)",
            "Launching"
        ]
        for (index, step) in steps.enumerated() {
            onEvent(.step(step, progress: Double(index) / Double(steps.count)))
            onEvent(.output(step))
            try await Task.sleep(for: .milliseconds(650))
        }
        return []
    }

    func locateProduct(_ request: BuildRequest, hints: [String]) async throws -> BuildProduct {
        BuildProduct(appPath: "/tmp/DerivedData/Build/Products/\(request.configuration)-\(request.isPhysicalDevice ? "iphoneos" : "iphonesimulator")/\(request.scheme).app", bundleID: "com.example.app")
    }
}
