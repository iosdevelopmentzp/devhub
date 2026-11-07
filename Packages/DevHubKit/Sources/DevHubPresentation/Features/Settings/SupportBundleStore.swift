import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class SupportBundleStore {
    private(set) var isBusy = false

    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let checkTools: CheckToolsUseCase
    @ObservationIgnored private let ci: any CIRepository
    @ObservationIgnored private let projects: CIProjectResolver
    @ObservationIgnored private let crashes: any CrashReportRepository
    @ObservationIgnored private let words: any RedactionWordsRepository
    @ObservationIgnored private let files: any TextFileRepository
    @ObservationIgnored private let commandLog: CommandLog
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let openRequests: any OpenRequestsLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let app: AppIdentity
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let chooseFile: (String) -> URL?

    static let fileNamePrefix = "DevHub support bundle"
    static let copyLabel = "Support bundle"
    static let crashAge: TimeInterval = 30 * 24 * 3_600

    init(
        settings: SettingsStore,
        session: ProjectSession,
        config: ConfigStore,
        checkTools: CheckToolsUseCase,
        ci: any CIRepository,
        projects: CIProjectResolver,
        crashes: any CrashReportRepository,
        words: any RedactionWordsRepository,
        files: any TextFileRepository,
        commandLog: CommandLog,
        checkout: any CheckoutContext,
        openRequests: any OpenRequestsLookup,
        activity: ActivityLog,
        toaster: Toaster,
        app: AppIdentity,
        now: @escaping () -> Date,
        chooseFile: @escaping (String) -> URL?
    ) {
        self.settings = settings
        self.session = session
        self.config = config
        self.checkTools = checkTools
        self.ci = ci
        self.projects = projects
        self.crashes = crashes
        self.words = words
        self.files = files
        self.commandLog = commandLog
        self.checkout = checkout
        self.openRequests = openRequests
        self.activity = activity
        self.toaster = toaster
        self.app = app
        self.now = now
        self.chooseFile = chooseFile
    }

    func copy() async {
        let text = await text()
        toaster.copy(text, label: Self.copyLabel)
        activity.log("Support bundle copied", detail: Self.detail(of: text), outcome: .info)
    }

    func save() async {
        guard let url = chooseFile("\(Self.fileNamePrefix) \(ISOTimestamp.fileName(now())).txt") else { return }
        let text = await text()
        do {
            try await files.write(text, to: url.path)
            activity.log("Support bundle saved", detail: "\(url.path). \(Self.detail(of: text))", outcome: .success)
        } catch {
            activity.log("Cannot save the support bundle", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func text() async -> String {
        isBusy = true
        defer { isBusy = false }
        let project = config.resolved.project
        let facts = SupportBundleBuilder.Facts(
            appVersion: app.version,
            systemVersion: app.systemVersion,
            date: now(),
            settings: settings.values,
            projectKind: project.kind?.rawValue,
            scheme: project.xcode?.scheme ?? meaningful(session.selectedProject.scheme),
            bundleID: project.xcode?.bundleID ?? meaningful(session.selectedProject.bundleID),
            configIssues: config.issues,
            tools: await checkTools.execute(DoctorPolicy.tools),
            ciProvider: projects.provider?.rawValue,
            ciSlug: projects.provider == nil ? nil : projects.project(for: []).slug,
            ciTool: await ciToolText(),
            crash: await lastCrash(),
            events: activity.events,
            commands: commandLog.entries
        )
        return RedactionPolicy.redact(SupportBundleBuilder.text(facts), subjects: subjects(), words: await redactionWords())
    }

    private func ciToolText() async -> String {
        guard projects.provider != nil else { return "not used" }
        do {
            let state = try await ci.toolState(project: projects.project(for: []))
            guard state.isInstalled else { return "not installed" }
            return "\(state.version ?? "unknown version"), \(state.isLoggedIn ? "logged in" : "not logged in")"
        } catch {
            return "unavailable (\(error.localizedDescription))"
        }
    }

    private func lastCrash() async -> CrashReport? {
        do {
            return try await crashes.ownReports(processName: app.processName, bundleID: app.bundleID, since: now().addingTimeInterval(-Self.crashAge)).first
        } catch {
            activity.log("Cannot read the crash reports of DevHub", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    private func redactionWords() async -> [RedactionWord] {
        do {
            return try await words.words()
        } catch {
            activity.log("Cannot read the redaction words", detail: error.localizedDescription, outcome: .failure)
            return []
        }
    }

    private func subjects() -> RedactionSubjects {
        let settings = checkout.gitSettings
        let host = checkout.webURL.flatMap { CodeHostPolicy.codeHost(webURL: $0, kind: settings.hostKind, name: settings.hostName) }
        let base = RedactionSubjectsMapper.subjects(
            host: host,
            currentBranch: checkout.currentBranch,
            baseName: checkout.baseName,
            requests: openRequests.requests,
            username: openRequests.username,
            home: app.home
        )
        let project = session.selectedProject.path.isEmpty ? nil : session.selectedProject
        return RedactionSubjectsMapper.adding(project: project, config: config.resolved.project, to: base)
    }

    private func meaningful(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }

    private static func detail(of text: String) -> String {
        "\(CountText.count(text.split(separator: "\n", omittingEmptySubsequences: false).count - 1, "line")), links, e-mails, tokens, paths and project names replaced"
    }
}
