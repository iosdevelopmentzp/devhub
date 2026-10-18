import Foundation

package struct ReadSimulatorStatusUseCase: Sendable {
    package static let timeout: Duration = .seconds(5)

    let scripts: any ScriptRunning
    let tools: any ToolLocating

    package func execute(_ request: SimulatorStatusRequest) async throws -> SimulatorStatusReading {
        let candidates = SimulatorStatusPolicy.candidates(script: request.script, layers: request.layers, projectPath: request.projectPath)
        guard let executable = candidates.first(where: tools.fileExists(atPath:)) else {
            throw SimulatorStatusError.notFound(request.script)
        }
        let run = ScriptRunRequest(executable: executable, arguments: [], cwd: ProjectPath(request.projectPath).expanded, environment: request.environment, timeout: Self.timeout)
        var lines: [String] = []
        var exitCode: Int32 = 0
        do {
            for try await event in scripts.run(run) {
                switch event {
                case let .output(line): lines.append(line)
                case let .exited(code): exitCode = code
                }
            }
        } catch ScriptError.timedOut {
            throw SimulatorStatusError.timedOut
        }
        let line = SimulatorStatusParser.parse(lines)
        guard exitCode == 0 else {
            throw SimulatorStatusError.exited(exitCode, lastLine: line)
        }
        return SimulatorStatusReading(line: line, state: SimulatorStatusParser.state(lines))
    }
}
