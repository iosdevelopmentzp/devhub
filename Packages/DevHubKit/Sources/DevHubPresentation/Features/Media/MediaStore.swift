import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class MediaStore {
    private(set) var outputs: [OperationOrigin: String] = [:]
    private(set) var busySources: Set<String> = []

    @ObservationIgnored private let repository: any MediaRepository
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private var tasks: [String: Task<Void, Never>] = [:]

    init(repository: any MediaRepository, operations: OperationLog, activity: ActivityLog) {
        self.repository = repository
        self.operations = operations
        self.activity = activity
    }

    func isBusy(_ source: String) -> Bool {
        busySources.contains(source)
    }

    func convert(_ source: String, to choice: MediaChoice, framedFor udid: String?, at origin: OperationOrigin) {
        guard MediaOutputPolicy.isVideo(source) else {
            activity.log("Cannot convert \(Self.fileName(source))", detail: "Choose a .mov, .mp4 or .m4v file.", outcome: .failure)
            return
        }
        let repository = repository
        if let options = choice.gifOptions {
            run(source, title: "GIF from \(Self.fileName(source))", at: origin) { progress in
                try await repository.makeGIF(from: source, options: options, framedFor: udid, onProgress: progress)
            }
        } else if let compression = choice.compression {
            run(source, title: "Compress \(Self.fileName(source))", at: origin) { _ in
                try await repository.compress(source, as: compression, framedFor: udid)
            }
        }
    }

    private func run(
        _ source: String,
        title: String,
        at origin: OperationOrigin,
        work: @escaping @Sendable (@escaping @Sendable (Double) -> Void) async throws -> String
    ) {
        guard busySources.contains(source) == false else { return }
        busySources.insert(source)
        let id = operations.start(
            title,
            at: origin,
            retry: nil,
            stop: { [weak self] in
                guard let self else { return }
                tasks[source]?.cancel()
            }
        )
        tasks[source] = Task { [weak self] in
            guard let self else { return }
            do {
                let destination = try await OperationScope.$current.withValue(id) {
                    try await work { fraction in
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            showProgress(fraction, of: id)
                        }
                    }
                }
                outputs[origin] = destination
                operations.succeed(id)
                activity.log(title, detail: Self.fileName(destination), outcome: .success)
            } catch {
                finish(id, title: title, error: error)
            }
            busySources.remove(source)
            tasks[source] = nil
        }
    }

    private func showProgress(_ fraction: Double, of id: OperationRecord.ID) {
        guard operations.record(id)?.isRunning == true else { return }
        operations.setProgress(of: id, text: "\(Int((fraction * 100).rounded())) %", fraction: fraction)
    }

    private func finish(_ id: OperationRecord.ID, title: String, error: any Error) {
        guard Task.isCancelled == false, error is CancellationError == false else {
            operations.cancel(id)
            activity.log(title, detail: "Cancelled", outcome: .info)
            return
        }
        operations.fail(id, message: error.localizedDescription)
        activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
    }

    private static func fileName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }
}
