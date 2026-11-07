import Foundation
import DevHubDomain

struct FileCrashReportRepository: CrashReportRepository {
    static let crashBugType = "309"

    let root: URL

    func reports(since: Date) async throws -> [CrashReport] {
        read(since: since) { $0.simulatorID != nil }
    }

    func ownReports(processName: String, bundleID: String?, since: Date) async throws -> [CrashReport] {
        read(since: since) { report in
            report.simulatorID == nil && report.processName == processName && (bundleID == nil || report.bundleID == nil || report.bundleID == bundleID)
        }
    }

    private func read(since: Date, keeping: (CrashReport) -> Bool) -> [CrashReport] {
        let files = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])) ?? []
        return files
            .filter { $0.pathExtension == "ips" }
            .compactMap { report(at: $0, since: since) }
            .filter(keeping)
            .sorted { $0.date > $1.date }
    }

    func changes() -> AsyncStream<Void> {
        let path = root.path
        return AsyncStream { continuation in
            let descriptor = open(path, O_EVTONLY)
            guard descriptor >= 0 else {
                continuation.finish()
                return
            }
            let box = SourceBox(DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .extend, .rename], queue: .global(qos: .utility)))
            box.source.setEventHandler { continuation.yield() }
            box.source.setCancelHandler { close(descriptor) }
            continuation.onTermination = { _ in box.source.cancel() }
            box.source.resume()
        }
    }

    private func report(at url: URL, since: Date) -> CrashReport? {
        let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
        guard modified >= since, let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        guard IPSCrashReportParser.header(text)?["bug_type"] as? String == Self.crashBugType else { return nil }
        return IPSCrashReportParser.parse(text, path: url.path, fallbackDate: modified)
    }
}

private final class SourceBox: @unchecked Sendable {
    let source: any DispatchSourceFileSystemObject

    init(_ source: any DispatchSourceFileSystemObject) {
        self.source = source
    }
}
