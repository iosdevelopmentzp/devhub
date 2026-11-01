import Foundation

package protocol AppDataRepository: Sendable {
    func read(udid: String, bundleID: String) async throws -> AppData
    func write(_ value: AppDefaultValue, key: String, plistPath: String, udid: String) async throws
    func delete(key: String, plistPath: String, udid: String) async throws
    func reset(_ data: AppData, udid: String, includingGroups: Bool) async throws
}
