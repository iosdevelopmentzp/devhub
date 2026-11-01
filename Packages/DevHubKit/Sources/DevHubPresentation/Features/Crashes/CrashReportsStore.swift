import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class CrashReportsStore {
    private(set) var crashes: [CrashReport] = []
    private(set) var dismissedIDs: Set<CrashReport.ID> = []
    private(set) var openIDs: Set<CrashReport.ID> = []

    @ObservationIgnored private let repository: any CrashReportRepository
    @ObservationIgnored private let prompts: any ReviewPromptRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private var launches: [String: CrashWatch] = [:]
    @ObservationIgnored private var watchTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(repository: any CrashReportRepository, prompts: any ReviewPromptRepository, activity: ActivityLog, notifier: Notifier, events: AppEvents) {
        self.repository = repository
        self.prompts = prompts
        self.activity = activity
        self.notifier = notifier
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case let .appLaunched(simulatorID, launch) = event, let launch, let bundleID = launch.bundleID else { return }
            watch(bundleID: bundleID, simulatorID: simulatorID, launchedAt: launch.date)
        }
    }

    var latest: CrashReport? {
        crashes.first { dismissedIDs.contains($0.id) == false }
    }

    var isWatching: Bool {
        watchTask != nil
    }

    func crash(_ id: CrashReport.ID) -> CrashReport? {
        crashes.first { $0.id == id }
    }

    func watch(bundleID: String, simulatorID: String, launchedAt: Date) {
        launches[bundleID] = CrashWatch(simulatorID: simulatorID, launchedAt: launchedAt)
        startWatching()
        Task { await check() }
    }

    func check() async {
        guard let since = launches.values.map(\.launchedAt).min() else { return }
        do {
            let reports = try await repository.reports(since: since.addingTimeInterval(-CrashReportPolicy.launchSlack))
            let known = Set(crashes.map(\.id))
            let new = reports.filter { report in
                known.contains(report.id) == false && launches.contains { bundleID, watch in
                    CrashReportPolicy.matches(report, bundleID: bundleID, simulatorID: watch.simulatorID, launchedAt: watch.launchedAt)
                }
            }
            for report in new.sorted(by: { $0.date < $1.date }) {
                record(report)
            }
        } catch {
            activity.log("Cannot read the crash reports", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func dismiss(_ id: CrashReport.ID) {
        dismissedIDs.insert(id)
        openIDs.remove(id)
    }

    func toggleReport(_ id: CrashReport.ID) {
        if openIDs.remove(id) == nil {
            openIDs.insert(id)
        }
    }

    func writeFixPrompt(id: CrashReport.ID, checkoutName: String) async -> String? {
        guard let report = crash(id) else { return nil }
        do {
            return try await prompts.save(FixPromptBuilder.crash(report, checkoutName: checkoutName), name: FixPromptBuilder.fileName(forCrashOf: report.processName))
        } catch {
            activity.log("Cannot write the fix prompt", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    private func record(_ report: CrashReport) {
        crashes.insert(report, at: 0)
        let title = "\(report.processName) crashed"
        let detail = CrashBannerMapper.detail(for: report)
        activity.log(title, detail: detail, outcome: .failure, kind: .crashes, target: .build)
        notifier.notify(.crashes, title: title, body: detail, target: .build)
    }

    private func startWatching() {
        guard watchTask == nil else { return }
        let changes = repository.changes()
        watchTask = Task { [weak self] in
            for await _ in changes {
                guard let self else { return }
                await check()
            }
        }
    }
}
