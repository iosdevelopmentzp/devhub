import Foundation

package struct FollowNetworkSourceUseCase: Sendable {
    let sources: any NetworkSourceRepository
    let tools: any ToolLocating

    package func execute(_ request: NetworkSourceRequest) -> AsyncThrowingStream<NetworkSourceEvent, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await follow(request) { continuation.yield($0) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func follow(_ request: NetworkSourceRequest, yield: (NetworkSourceEvent) -> Void) async throws {
        let candidates = SimulatorStatusPolicy.candidates(script: request.script, layers: request.layers, projectPath: request.projectPath)
        guard let executable = candidates.first(where: tools.fileExists(atPath:)) else {
            throw NetworkSourceError.notFound(request.script)
        }
        let run = ScriptRunRequest(executable: executable, arguments: [], cwd: ProjectPath(request.projectPath).expanded, environment: request.environment)
        var lastLine: String?
        for try await event in sources.follow(run) {
            switch event {
            case let .output(line):
                let trimmed = line.trimmed
                if trimmed.isEmpty == false {
                    lastLine = trimmed
                }
            case let .exited(code):
                guard code == 0 || Task.isCancelled else {
                    throw NetworkSourceError.exited(code, lastLine: lastLine)
                }
            case .request, .error:
                yield(event)
            }
        }
    }
}
