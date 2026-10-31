import Foundation

package struct CommandRunUseCase: Sendable {
    package let scripts: any ScriptRunning
    package let build: any BuildRepository
    package let simulators: any SimulatorRepository
    package let install: AppInstallStep

    package init(scripts: any ScriptRunning, build: any BuildRepository, simulators: any SimulatorRepository, install: AppInstallStep) {
        self.scripts = scripts
        self.build = build
        self.simulators = simulators
        self.install = install
    }

    package func run(_ request: CommandRunRequest) -> AsyncThrowingStream<BuildEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await pipeline(request, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func pipeline(_ request: CommandRunRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws {
        let target = request.target
        continuation.yield(.step("Booting \(target.simulatorName)", progress: nil))
        try await simulators.boot(udid: target.simulatorUDID)
        try Task.checkCancellation()

        var appPath: String?
        for (key, command) in commands(of: request) {
            guard let command else { continue }
            continuation.yield(.step("Running \(key)", progress: nil))
            appPath = try await runCommand(command, key: key, request: request, continuation: continuation) ?? appPath
            try Task.checkCancellation()
        }

        guard target.launchesApp else {
            continuation.yield(.output(appPath.map { "App: \($0)" } ?? (request.buildCommand == nil ? "No build.command: nothing to build." : "build.command finished.")))
            return
        }
        guard let appPath else {
            continuation.yield(.output("No app directive: the commands launch the app themselves."))
            return
        }
        let product = try build.product(atAppPath: appPath)
        continuation.yield(.output("App: \(product.appPath)"))
        try await install.run(product, request: target, continuation: continuation)
    }

    private func commands(of request: CommandRunRequest) -> [(String, String?)] {
        let build = ("build.command", request.buildCommand)
        guard request.target.launchesApp else { return [build] }
        return [build, ("run.command", request.runCommand)]
    }

    private func runCommand(_ command: String, key: String, request: CommandRunRequest, continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation) async throws -> String? {
        let executable = command.hasPrefix("/") ? command : (request.folder as NSString).appendingPathComponent(command)
        var appPath: String?
        var reportedError: String?
        var exitCode: Int32 = 0
        for try await event in scripts.run(ScriptRunRequest(executable: executable, arguments: [], cwd: request.folder, environment: request.environment)) {
            switch event {
            case .output(let line):
                guard case .directives(let directives) = ScriptDirectiveParser.parse(line) else {
                    continuation.yield(.output(line))
                    continue
                }
                for directive in directives {
                    switch directive {
                    case .progress(let text, let fraction):
                        continuation.yield(.step(text, progress: fraction))
                    case .app(let path):
                        appPath = path.hasPrefix("/") ? path : (request.folder as NSString).appendingPathComponent(path)
                    case .error(let message):
                        reportedError = message
                    case .toast, .copy, .open, .notify, .refresh, .view, .state:
                        break
                    }
                }
            case .exited(let code):
                exitCode = code
            }
        }
        if let reportedError {
            throw BuildError.failed(reportedError)
        }
        guard exitCode == 0 else {
            throw BuildError.failed("\(key) exited with code \(exitCode).")
        }
        return appPath
    }
}
