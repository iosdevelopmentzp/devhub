import Foundation

package protocol AppLogRepository: Sendable {
    func executableName(udid: String, bundleID: String) async -> String?
    func stream(udid: String, process: String) -> AsyncThrowingStream<AppLogLine, Error>
}
