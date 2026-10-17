import Foundation

nonisolated final class ConfigWatcher: ConfigWatching, @unchecked Sendable {
    private let paths: [String]
    private let onChange: @Sendable () -> Void
    private let queue = DispatchQueue(label: "DevHub.ConfigWatcher")
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private var timer: DispatchSourceTimer?
    private var pending: DispatchWorkItem?
    private var fingerprint = ""
    private var isStopped = false

    init(paths: [String], onChange: @escaping @Sendable () -> Void) {
        self.paths = paths
        self.onChange = onChange
        queue.async { [self] in
            arm()
            fingerprint = computeFingerprint()
            startTimer()
        }
    }

    func stop() {
        queue.async { [self] in
            isStopped = true
            pending?.cancel()
            timer?.cancel()
            timer = nil
            sources.values.forEach { $0.cancel() }
            sources.removeAll()
        }
    }

    deinit {
        timer?.cancel()
        sources.values.forEach { $0.cancel() }
    }

    private func arm() {
        for path in paths where sources[path] == nil {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
            let descriptor = open(path, O_EVTONLY)
            guard descriptor >= 0 else { continue }
            let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .delete, .rename, .extend], queue: queue)
            source.setEventHandler { [weak self] in
                guard let self else { return }
                handle(path: path)
            }
            source.setCancelHandler {
                close(descriptor)
            }
            source.resume()
            sources[path] = source
        }
    }

    private func handle(path: String) {
        if let source = sources[path], source.data.contains(.delete) || source.data.contains(.rename) {
            source.cancel()
            sources[path] = nil
        }
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            checkForChange()
        }
        pending = item
        queue.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            checkForChange()
        }
        timer.resume()
        self.timer = timer
    }

    private func checkForChange() {
        guard isStopped == false else { return }
        arm()
        let current = computeFingerprint()
        guard current != fingerprint else { return }
        fingerprint = current
        onChange()
    }

    private func computeFingerprint() -> String {
        let manager = FileManager.default
        var parts: [String] = []
        for path in paths {
            let names = (try? manager.contentsOfDirectory(atPath: path)) ?? []
            parts.append("\(path):\(names.isEmpty && manager.fileExists(atPath: path) == false ? "missing" : "present")")
            for name in names.sorted() {
                let attributes = try? manager.attributesOfItem(atPath: path + "/" + name)
                let stamp = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
                let size = (attributes?[.size] as? NSNumber)?.intValue ?? 0
                parts.append("\(name)|\(stamp)|\(size)")
            }
        }
        return parts.joined(separator: "\n")
    }
}
