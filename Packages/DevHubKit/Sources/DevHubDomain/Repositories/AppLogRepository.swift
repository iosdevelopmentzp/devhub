import Foundation

package protocol AppLogRepository: Sendable {
    func executableName(udid: String, bundleID: String) async -> String?
    func stream(udid: String, filter: AppLogFilter) -> AsyncThrowingStream<AppLogLine, Error>
}
