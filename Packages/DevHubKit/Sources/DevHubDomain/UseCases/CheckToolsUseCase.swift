import Foundation

package struct CheckToolsUseCase: Sendable {
    let scripts: any ScriptRunning
    let tools: any ToolLocating

    package func execute(_ list: [DoctorTool]) async -> [ToolStatus] {
        await withTaskGroup(of: (Int, ToolStatus).self) { group in
            for (index, tool) in list.enumerated() {
                group.addTask {
                    (index, await status(of: tool))
                }
            }
            var results: [(Int, ToolStatus)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private func status(of tool: DoctorTool) async -> ToolStatus {
        guard let path = tools.path(of: tool.name) else {
            return ToolStatus(tool: tool, path: nil, version: nil)
        }
        var lines: [String] = []
        let request = ScriptRunRequest(executable: path, arguments: tool.versionArguments, cwd: nil, environment: [:], timeout: DoctorPolicy.timeout)
        do {
            for try await event in scripts.run(request) {
                if case let .output(line) = event {
                    lines.append(line)
                }
            }
        } catch {
            return ToolStatus(tool: tool, path: path, version: nil)
        }
        let version = tool.name == "xcrun" ? "simctl" : DoctorPolicy.version(from: lines)
        return ToolStatus(tool: tool, path: path, version: version, latestVersion: DoctorPolicy.latestVersion(from: lines))
    }
}
