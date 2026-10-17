import Foundation
import Observation

@MainActor
@Observable
final class ProjectSession {
    private(set) var projects: [Project]
    private(set) var project: Project?
    private(set) var detections: [String: ProjectDetection] = [:]
    private(set) var summary: GitSummary = .notARepository
    private(set) var repository: RepositoryLink?
    private(set) var checkoutPath: String?
    private(set) var checkoutBranch: String?
    private(set) var target: TargetSimulator?
    private(set) var lastAppPath: String?
    var searchText = ""

    @ObservationIgnored private let preferences: AppPreferences
    @ObservationIgnored private let git: GitRepositoryProviding
    @ObservationIgnored private let detector: ProjectDetecting
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster

    init(preferences: AppPreferences, git: GitRepositoryProviding, detector: ProjectDetecting, events: AppEvents, activity: ActivityLog, toaster: Toaster) {
        self.preferences = preferences
        self.git = git
        self.detector = detector
        self.events = events
        self.activity = activity
        self.toaster = toaster
        let saved = preferences.value([Project].self, for: .projects) ?? []
        projects = saved
        let selected = preferences.string(.projectPath)
        project = saved.first { $0.path == selected } ?? saved.first
    }

    var branch: String? { summary.branch }

    var activeCheckoutPath: String? { checkoutPath ?? project?.path }

    var activeBranch: String? { checkoutBranch ?? summary.branch }

    var hasProject: Bool { project != nil }

    var detection: ProjectDetection? {
        project.flatMap { detections[$0.path] }
    }

    var isSearching: Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty == false
    }

    func setCheckout(path: String?, branch: String?) {
        checkoutPath = path
        checkoutBranch = branch
    }

    func setTarget(_ value: TargetSimulator?) {
        target = value
    }

    func setLastAppPath(_ path: String?) {
        lastAppPath = path
    }

    func matchesSearch(_ values: String...) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.isEmpty == false else { return true }
        return values.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    func start() async {
        await withTaskGroup(of: Void.self) { group in
            for project in projects {
                group.addTask { await self.detect(project) }
            }
        }
        await refresh()
        events.post(.projectChanged)
    }

    func addUsingPicker() {
        guard let path = FilePicker.pickFolder(message: "Choose a project folder") else { return }
        add(path: path)
    }

    func add(path: String) {
        let standard = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standard, isDirectory: &isDirectory), isDirectory.boolValue else {
            activity.log("Add project", detail: "\(standard) is not a folder.", outcome: .failure)
            toaster.show("Not a folder: \(standard)", tint: .red)
            return
        }
        let added = Project(path: standard)
        if projects.contains(added) == false {
            projects.append(added)
            saveProjects()
            activity.log("Add project", detail: standard, outcome: .success)
        }
        select(added)
    }

    func select(_ target: Project) {
        guard projects.contains(target) else { return }
        guard project != target else { return }
        project = target
        preferences.set(target.path, for: .projectPath)
        summary = .notARepository
        repository = nil
        checkoutPath = nil
        checkoutBranch = nil
        events.post(.projectChanged)
        Task {
            await detectIfNeeded(target)
            await refresh()
        }
    }

    func remove(_ target: Project) {
        projects.removeAll { $0 == target }
        detections[target.path] = nil
        saveProjects()
        activity.log("Remove project", detail: target.path, outcome: .info)
        guard project == target else { return }
        project = projects.first
        preferences.set(project?.path, for: .projectPath)
        summary = .notARepository
        repository = nil
        checkoutPath = nil
        checkoutBranch = nil
        events.post(.projectChanged)
        Task { await refresh() }
    }

    func redetect(_ target: Project) async {
        await detect(target)
        activity.log("Detect project", detail: target.path, outcome: .success)
    }

    func refresh() async {
        guard let current = project else { return }
        let newSummary = await git.summary(at: current.path)
        let remote = await git.remoteURL(at: current.path)
        guard project == current else { return }
        summary = newSummary
        repository = remote.flatMap { RepositoryLink.parse(remote: $0) }
    }

    private func detectIfNeeded(_ target: Project) async {
        guard detections[target.path] == nil else { return }
        await detect(target)
    }

    private func detect(_ target: Project) async {
        detections[target.path] = await detector.detect(path: target.path)
    }

    private func saveProjects() {
        preferences.setValue(projects, for: .projects)
    }
}
