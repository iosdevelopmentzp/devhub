import Foundation

package protocol UpdateRepository: Sendable {
    func installed() async throws -> InstalledBuild?
    func check(installed: InstalledBuild) async throws -> UpdateCheck
    func start(installed: InstalledBuild) async throws
    func status() async throws -> UpdateStatus?
    func isUpdateRunning() async -> Bool
    func clearStatus() async throws
    func log() async throws -> String?
}
