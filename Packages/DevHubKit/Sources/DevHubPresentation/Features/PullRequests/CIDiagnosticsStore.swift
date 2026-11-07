import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class CIDiagnosticsStore {
    private(set) var isBusy = false

    @ObservationIgnored private let ci: any CIRepository
    @ObservationIgnored private let words: any RedactionWordsRepository
    @ObservationIgnored private let files: any TextFileRepository
    @ObservationIgnored private let commandLog: CommandLog
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let projects: CIProjectResolver
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let openRequests: any OpenRequestsLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let home: String
    @ObservationIgnored private let appVersion: String
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let chooseFile: (String) -> URL?

    static let fileNamePrefix = "DevHub CI diagnostics"
    static let copyLabel = "CI diagnostics"

    init(
        ci: any CIRepository,
        words: any RedactionWordsRepository,
        files: any TextFileRepository,
        commandLog: CommandLog,
        config: ConfigStore,
        projects: CIProjectResolver,
        checkout: any CheckoutContext,
        openRequests: any OpenRequestsLookup,
        activity: ActivityLog,
        toaster: Toaster,
        home: String,
        appVersion: String,
        now: @escaping () -> Date,
        chooseFile: @escaping (String) -> URL?
    ) {
        self.ci = ci
        self.words = words
        self.files = files
        self.commandLog = commandLog
        self.config = config
        self.projects = projects
        self.checkout = checkout
        self.openRequests = openRequests
        self.activity = activity
        self.toaster = toaster
        self.home = home
        self.appVersion = appVersion
        self.now = now
        self.chooseFile = chooseFile
    }

    func copy(_ snapshot: CIDiagnosticsSnapshot) async {
        let text = await text(for: snapshot)
        toaster.copy(text, label: Self.copyLabel)
        activity.log("CI diagnostics copied", detail: Self.detail(of: text), outcome: .info)
    }

    func save(_ snapshot: CIDiagnosticsSnapshot) async {
        guard let url = chooseFile("\(Self.fileNamePrefix) \(ISOTimestamp.fileName(now())).txt") else { return }
        let text = await text(for: snapshot)
        do {
            try await files.write(text, to: url.path)
            activity.log("CI diagnostics saved", detail: "\(url.path). \(Self.detail(of: text))", outcome: .success)
        } catch {
            activity.log("Cannot save the CI diagnostics", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func text(for snapshot: CIDiagnosticsSnapshot) async -> String {
        isBusy = true
        defer { isBusy = false }
        let project = projects.project(for: [])
        var toolState: CIToolState?
        var toolError: String?
        if projects.provider != nil {
            do {
                toolState = try await ci.toolState(project: project)
            } catch {
                toolError = error.localizedDescription
            }
        }
        let settings = checkout.gitSettings
        let host = checkout.webURL.flatMap { CodeHostPolicy.codeHost(webURL: $0, kind: settings.hostKind, name: settings.hostName) }
        let facts = CIDiagnosticsBuilder.Facts(
            appVersion: appVersion,
            date: now(),
            provider: projects.provider,
            slug: project.slug,
            checkoutPath: checkout.checkoutPath,
            ciConfig: config.resolved.project.ci,
            hostKind: host?.kind,
            currentBranch: checkout.currentBranch,
            baseBranch: checkout.baseName,
            toolState: toolState,
            toolError: toolError,
            snapshot: snapshot,
            failures: CIDiagnosticsBuilder.ciFailures(in: activity.events),
            commands: CIDiagnosticsBuilder.ciCommands(in: commandLog.entries)
        )
        var redactionWords: [RedactionWord] = []
        do {
            redactionWords = try await words.words()
        } catch {
            activity.log("Cannot read the redaction words", detail: error.localizedDescription, outcome: .failure)
        }
        let subjects = CIDiagnosticsSubjectsMapper.subjects(
            host: host,
            currentBranch: checkout.currentBranch,
            baseName: checkout.baseName,
            requests: openRequests.requests,
            username: openRequests.username,
            home: home
        )
        return CIRedactionPolicy.redact(CIDiagnosticsBuilder.text(facts), subjects: subjects, words: redactionWords)
    }

    private static func detail(of text: String) -> String {
        "\(CountText.count(text.split(separator: "\n", omittingEmptySubsequences: false).count - 1, "line")), project names and branches replaced"
    }
}
