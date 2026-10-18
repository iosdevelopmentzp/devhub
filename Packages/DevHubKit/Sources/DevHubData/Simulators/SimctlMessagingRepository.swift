import Foundation
import DevHubDomain

struct SimctlMessagingRepository: SimulatorMessagingRepository {
    let simctl: SimctlRunner

    init(shell: ShellRunner) {
        simctl = SimctlRunner(shell: shell)
    }

    func openURL(_ url: String, udid: String) async throws {
        try await simctl.run(["openurl", udid, url], failure: SimulatorError.command)
    }

    func sendPush(_ payload: String, bundleID: String, udid: String) async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("devhub-push-\(UUID().uuidString).apns")
        try payload.write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: file) }
        try await simctl.run(["push", udid, bundleID, file.path], failure: SimulatorError.command)
    }

    func urlSchemes(bundleID: String, udid: String) async -> [String] {
        guard let result = try? await simctl.run(["get_app_container", udid, bundleID, "app"], failure: SimulatorError.command) else { return [] }
        let app = URL(fileURLWithPath: result.stdout.trimmed)
        return AppURLSchemeParser.schemes(in: PlistReader.dictionary(at: app.appendingPathComponent("Info.plist")))
    }
}
