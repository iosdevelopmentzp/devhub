import Foundation

@MainActor
extension DebugLaunch {
    static func startLogStreams(_ specification: String, in dependencies: AppDependencies) {
        Task {
            await dependencies.logs.refreshSimulators()
            for item in specification.split(separator: ",") {
                let parts = item.split(separator: ":", maxSplits: 1).map(String.init)
                guard let udid = parts.first else { continue }
                let name = dependencies.logs.availableSimulators.first { $0.id == udid }?.name ?? udid
                dependencies.logs.startStream(udid: udid, name: name)
                if parts.count > 1 {
                    dependencies.logs.setProcess(parts[1], for: udid)
                }
            }
            for stream in dependencies.logs.streams {
                dependencies.logs.stop(stream.id)
                dependencies.logs.start(stream.id)
            }
            try? await Task.sleep(for: .seconds(5))
            for stream in dependencies.logs.streams {
                report("STREAM \(stream.id) running=\(stream.isRunning) lines=\(stream.lines.count) dropped=\(stream.dropped) error=\(stream.error ?? "none")")
            }
        }
    }

    static func checkRedaction() {
        let samples = [
            "Authorization: Bearer abc.def-123",
            "sent Bearer abc123xyz to server",
            "jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMiJ9.sig_nature ok",
            "{\"access_token\":\"secret-value\",\"user\":\"x\"}",
            "url?token=abc123&page=2",
            "password = hunter2 and api_key: k-1",
            "x-auth-token: 99aa",
            "plain message with no secrets"
        ]
        for sample in samples {
            report("REDACT \(sample) -> \(LogRedactor.redact(sample))")
        }
    }

    private static func report(_ text: String) {
        FileHandle.standardError.write(Data((text + "\n").utf8))
    }
}
