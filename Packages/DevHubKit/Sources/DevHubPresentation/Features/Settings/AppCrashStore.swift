import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class AppCrashStore {
    private(set) var latest: CrashReport?

    @ObservationIgnored private let crashes: any CrashReportRepository
    @ObservationIgnored private let words: any RedactionWordsRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let app: AppIdentity
    @ObservationIgnored private let now: () -> Date

    static let seenKey = "app.crashSeenAt"
    static let firstLookBack: TimeInterval = 3 * 24 * 3_600
    static let copyLabel = "Crash report"

    init(crashes: any CrashReportRepository, words: any RedactionWordsRepository, activity: ActivityLog, toaster: Toaster, store: any KeyValueStore, app: AppIdentity, now: @escaping () -> Date) {
        self.crashes = crashes
        self.words = words
        self.activity = activity
        self.toaster = toaster
        self.store = store
        self.app = app
        self.now = now
    }

    var notice: String? {
        latest.map(AppCrashText.notice)
    }

    func check() async {
        let since = store.decode(Date.self, forKey: Self.seenKey) ?? now().addingTimeInterval(-Self.firstLookBack)
        do {
            let reports = try await crashes.ownReports(processName: app.processName, bundleID: app.bundleID, since: since)
            guard let newest = reports.first(where: { $0.date > since }) else { return }
            latest = newest
            activity.log("DevHub crashed", detail: CrashBannerMapper.detail(for: newest), outcome: .failure)
        } catch {
            activity.log("Cannot read the crash reports of DevHub", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func copy() async {
        guard let latest else { return }
        var redactionWords: [RedactionWord] = []
        do {
            redactionWords = try await words.words()
        } catch {
            activity.log("Cannot read the redaction words", detail: error.localizedDescription, outcome: .failure)
        }
        let text = (["DevHub crash report", "DevHub: \(app.version)", "macOS: \(app.systemVersion)", ""] + AppCrashText.lines(latest)).joined(separator: "\n") + "\n"
        let subjects = RedactionSubjects(homeFolder: app.home, userName: (app.home as NSString).lastPathComponent)
        toaster.copy(RedactionPolicy.redact(text, subjects: subjects, words: redactionWords), label: Self.copyLabel)
    }

    func dismiss() {
        guard let latest else { return }
        store.encode(latest.date, forKey: Self.seenKey)
        self.latest = nil
    }
}
