import Foundation
import DevHubDomain

struct MockAppDataRepository: AppDataRepository {
    func read(udid: String, bundleID: String) async throws -> AppData {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.appData
    }

    func write(_ value: AppDefaultValue, key: String, plistPath: String, udid: String) async throws {
        try? await Task.sleep(for: .milliseconds(200))
    }

    func delete(key: String, plistPath: String, udid: String) async throws {
        try? await Task.sleep(for: .milliseconds(200))
    }

    func reset(_ data: AppData, udid: String, includingGroups: Bool) async throws {
        try? await Task.sleep(for: .milliseconds(400))
    }
}
