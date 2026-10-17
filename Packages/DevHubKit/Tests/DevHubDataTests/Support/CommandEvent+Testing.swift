import DevHubDomain

extension CommandEvent {
    var stage: String {
        switch payload {
        case .started: "started"
        case .output: "output"
        case .finished: "finished"
        }
    }

    var startedCommand: String? {
        guard case .started(let command, _, _) = payload else { return nil }
        return command
    }

    var startedKind: CommandKind? {
        guard case .started(_, _, let kind) = payload else { return nil }
        return kind
    }

    var outputLines: [String]? {
        guard case .output(let lines) = payload else { return nil }
        return lines
    }

    var finishedExitCode: Int32? {
        guard case .finished(let exitCode, _) = payload else { return nil }
        return exitCode
    }

    var finishedError: String? {
        guard case .finished(_, let error) = payload else { return nil }
        return error
    }
}
