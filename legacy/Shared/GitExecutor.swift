import Foundation

@MainActor
final class GitExecutor {
    private let provider: GitRepositoryProviding
    private let activity: ActivityLog
    private let toaster: Toaster

    init(provider: GitRepositoryProviding, activity: ActivityLog, toaster: Toaster) {
        self.provider = provider
        self.activity = activity
        self.toaster = toaster
    }

    func perform(_ command: GitCommand, at path: String, title: String? = nil) async -> ShellResult? {
        let name = title ?? command.title
        do {
            let result = try await provider.run(command, at: path)
            if result.exitCode == 0 {
                activity.log(name, detail: URL(fileURLWithPath: path).lastPathComponent, outcome: .success)
            } else {
                fail(name, message: result.failureMessage)
            }
            return result.exitCode == 0 ? result : nil
        } catch {
            fail(name, message: error.localizedDescription)
            return nil
        }
    }

    func succeeds(_ command: GitCommand, at path: String) async -> Bool {
        guard let result = try? await provider.run(command, at: path) else { return false }
        return result.exitCode == 0
    }

    func fail(_ title: String, message: String) {
        let summary = message.split(whereSeparator: \.isNewline).first.map(String.init) ?? message
        activity.log(title, detail: message, outcome: .failure)
        toaster.show("\(title) failed: \(summary)", tint: .red)
    }
}
