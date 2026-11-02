import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class VideoCompressionStore {
    private(set) var engine: VideoEngineStatus?
    private(set) var isCheckingEngine = false
    private(set) var install: VideoInstallState = .idle
    private(set) var jobs: [VideoJob] = []
    var settings: VideoCompressionSettings {
        didSet {
            guard settings != oldValue else { return }
            store.encode(settings, forKey: Keys.settings)
        }
    }

    @ObservationIgnored private let repository: any VideoCompressionRepository
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var queue: Task<Void, Never>?
    @ObservationIgnored private var running: (id: VideoJob.ID, task: Task<Void, Never>)?

    private enum Keys {
        static let settings = "utils.video.settings"
    }

    init(repository: any VideoCompressionRepository, store: any KeyValueStore, activity: ActivityLog, notifier: Notifier, toaster: Toaster, now: @escaping () -> Date) {
        self.repository = repository
        self.store = store
        self.activity = activity
        self.notifier = notifier
        self.toaster = toaster
        self.now = now
        settings = store.decode(VideoCompressionSettings.self, forKey: Keys.settings) ?? .standard
    }

    var isEngineReady: Bool {
        engine?.isReady == true
    }

    var hasFinishedJobs: Bool {
        jobs.contains(where: \.isFinished)
    }

    // MARK: Engine

    func checkEngine() async {
        guard isCheckingEngine == false, install.isRunning == false else { return }
        isCheckingEngine = true
        let status = await repository.engineStatus()
        isCheckingEngine = false
        if status != engine {
            engine = status
        }
        startQueue()
    }

    func installEngine() {
        guard install.isRunning == false else { return }
        install = .running(step: "Starting brew install ffmpeg")
        let onStep: @Sendable (String) -> Void = { [weak self] step in
            Task { @MainActor [weak self] in
                guard let self, install.isRunning else { return }
                install = .running(step: step)
            }
        }
        Task { [weak self, repository] in
            do {
                try await repository.installEngine(onStep: onStep)
                guard let self else { return }
                install = .idle
                await checkEngine()
                activity.log("Installed ffmpeg", detail: "brew install ffmpeg", outcome: .success)
                toaster.show("ffmpeg is installed")
            } catch {
                guard let self else { return }
                install = .failed(error.localizedDescription)
                activity.log("Could not install ffmpeg", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    // MARK: Jobs

    func add(paths: [String]) {
        let others = paths.filter { VideoCompressionPolicy.isVideo($0) == false }
        for path in others {
            let name = (path as NSString).lastPathComponent
            activity.log("Cannot compress \(name)", detail: VideoCompressionError.notAVideo(name).localizedDescription, outcome: .failure)
        }
        if let first = others.first {
            toaster.show(VideoCompressionError.notAVideo((first as NSString).lastPathComponent).localizedDescription)
        }
        let queued = Set(jobs.filter { $0.isFinished == false }.map(\.source))
        let videos = paths.filter { VideoCompressionPolicy.isVideo($0) && queued.contains($0) == false }
        guard videos.isEmpty == false else { return }
        jobs.append(contentsOf: videos.map { VideoJob(id: UUID(), source: $0, settings: settings, info: nil, state: .waiting) })
        if engine == nil {
            Task { await checkEngine() }
        } else {
            startQueue()
        }
    }

    func compressAgain(_ id: VideoJob.ID) {
        guard let job = jobs.first(where: { $0.id == id }) else { return }
        jobs.append(VideoJob(id: UUID(), source: job.source, settings: settings, info: nil, state: .waiting))
        startQueue()
    }

    func stop(_ id: VideoJob.ID) {
        if running?.id == id {
            running?.task.cancel()
            return
        }
        update(id) { job in
            guard job.state == .waiting else { return }
            job.state = .stopped
        }
    }

    func remove(_ id: VideoJob.ID) {
        guard running?.id != id else { return }
        jobs.removeAll { $0.id == id }
    }

    func clearFinished() {
        jobs.removeAll(where: \.isFinished)
    }

    private func startQueue() {
        guard queue == nil, isEngineReady, jobs.contains(where: { $0.state == .waiting }) else { return }
        queue = Task { [weak self] in
            guard let self else { return }
            while let job = jobs.first(where: { $0.state == .waiting }) {
                let task = Task { [weak self] in
                    guard let self else { return }
                    await run(job)
                }
                running = (job.id, task)
                await task.value
                running = nil
            }
            queue = nil
        }
    }

    private func run(_ job: VideoJob) async {
        let started = now()
        update(job.id) { $0.state = .reading }
        do {
            let info = try await repository.info(of: job.source)
            try Task.checkCancellation()
            update(job.id) { job in
                job.info = info
                job.state = .compressing(VideoCompressionProgress(seconds: 0, speed: nil))
            }
            let result = try await repository.compress(job.source, info: info, settings: job.settings) { progress in
                Task { @MainActor [weak self] in
                    self?.show(progress, of: job.id)
                }
            }
            try Task.checkCancellation()
            update(job.id) { $0.state = .done(result, seconds: now().timeIntervalSince(started)) }
            finish(job, result: result, original: info.size)
        } catch {
            fail(job, error: error)
        }
    }

    private func show(_ progress: VideoCompressionProgress, of id: VideoJob.ID) {
        update(id) { job in
            guard case .compressing = job.state else { return }
            job.state = .compressing(progress)
        }
    }

    private func finish(_ job: VideoJob, result: VideoCompressionResult, original: Int64) {
        let detail = VideoCompressionText.change(original: original, compressed: result.size)
        let name = (result.path as NSString).lastPathComponent
        activity.log("Compressed \(job.name)", detail: "\(name) · \(detail)", outcome: .success, kind: .utilities, target: .utilities)
        notifier.notify(.utilities, title: "Video compressed: \(job.name)", body: detail, target: .utilities)
    }

    private func fail(_ job: VideoJob, error: any Error) {
        guard Task.isCancelled == false, error is CancellationError == false else {
            update(job.id) { $0.state = .stopped }
            activity.log("Stopped compressing \(job.name)", detail: "No file was written.", outcome: .info)
            return
        }
        update(job.id) { $0.state = .failed(error.localizedDescription) }
        activity.log("Could not compress \(job.name)", detail: error.localizedDescription, outcome: .failure, kind: .utilities, target: .utilities)
        notifier.notify(.utilities, title: "Could not compress \(job.name)", body: error.localizedDescription, target: .utilities)
    }

    private func update(_ id: VideoJob.ID, _ change: (inout VideoJob) -> Void) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        change(&jobs[index])
    }
}
