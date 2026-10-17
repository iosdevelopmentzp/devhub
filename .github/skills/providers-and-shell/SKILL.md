---
name: providers-and-shell
description: "The data layer of DevHub: ShellRunner (run and stream, PATH, environment, cancellation, the deadlock trap), CommandLog and command classification, provider protocols with mock and live implementations, AsyncThrowingStream for long work, injection into stores, threading and error rules. Load when a task runs git, xcrun, xcodebuild or any process, or replaces mock data with real data."
---

# Providers and Shell

Views do not change when data turns real. A store keeps its public surface. Only the source moves from `MockData` to a live provider.

## Structure

```
DevHub/Services/
    ShellRunner.swift        actor: run(...) and stream(...), every call recorded; ShellResult, DataReader
    CommandRecorder.swift    CommandRecorder (thread-safe hop to the main queue) and LineBatcher (0.25 s batches)
    CommandLog.swift         main actor store: 300 entries, newest first, 4 000 lines per entry, onFailure
    Providers.swift          struct Providers { git, hosting, worktrees, build, simulators, logs, ai, usage, config, projects, tools, workspace }  with .mock and .live (a provider without a live type, now only build, uses its mock in .live)
    Git/                     GitRepositoryProviding (+ Mock, LiveGitRepositoryProvider; reads and `run(_:at:)` for writes), WorktreeProviding (+ Mock, LiveWorktreeProvider, DerivedDataLocator), PullRequestProviding (+ Mock, LivePullRequestProvider: `gh` and `glab` JSON, install hint when missing)
    Xcode/                   BuildProvider (xcodebuild pipeline and command pipeline), XcodeContainer, ProductLocator, DerivedData
    Simulators/              SimulatorProviding (+ Mock, LiveSimulatorProvider: `list()`, `executableName(simulatorID:bundleID:)`); later LaunchProvider (profiles, clean install, launch), MessagingProvider (openurl, push)
    Logs/                    AppLogProviding (+ Mock, LiveAppLogProvider: `stream(simulatorID:filter:)`)
    AI/                      AISessionProviding (+ Mock, LiveAISessionProvider with the `AISessionIndex` actor, SessionFile), UsageProviding (+ Mock, LiveUsageProvider for Claude and Copilot, UsageHTTP)
    Config/                  ConfigProviding (+ Mock, LiveConfigProvider: read folders, create example), ConfigWatcher (DispatchSource plus fingerprint timer)
    BackgroundWork.swift     offMain { } runs blocking file work off the main actor (nonisolated async runs on the caller's actor here)
    Workspace/               WorkspaceActing (+ Mock, LiveWorkspaceActions: open -a, open <url>, the temporary .command script), ProjectDetecting (+ Mock, LiveProjectDetector), ToolLocating, FilePicker (NSOpenPanel), Clipboard (only `Toaster` calls it), GlobalHotKey; later XcodeAttacher   (AppKit allowed here only)
```

Parsers are in `DevHub/Core/Parsers/` and are pure: input text, output values. Providers call them. Examples: `CommandClassifier`, `CommandDisplay`, `GitStatusV2Parser`, `SimulatorListParser`, `LogLineParser` (also redacts), `CopilotUsageParser`, `ClaudeUsageParser`. Git writes are values of `GitCommand` (Core): stores never build git arguments; `GitExecutor` (Shared) runs one, logs it in `ActivityLog` and toasts a failure.

Protocols and all provider and model types are `nonisolated` (default isolation is `MainActor`). Providers are `Sendable` structs.

## ShellRunner

```swift
nonisolated struct ShellResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    var failureMessage: String   // stderr, else stdout, else "Exited with code N."
}

actor ShellRunner {
    nonisolated static let shared = ShellRunner(recorder: .shared)
    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String] = [:]) async throws -> ShellResult
    func stream(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String] = [:], onLine: @escaping @Sendable (String) -> Void) async throws -> Int32
}
```

- Launch through `/usr/bin/env <executable>`; prepend `/opt/homebrew/bin:/usr/local/bin` to `PATH`; merge extra environment; expand `~` in `cwd`.
- **The deadlock trap.** `readDataToEndOfFile()` on the Swift concurrency pool plus a stderr reader on a global GCD queue hangs under 30+ parallel commands. Do the blocking work on a dedicated `DispatchQueue(label: "DevHub.ShellRunner", attributes: .concurrent)`: `withCheckedThrowingContinuation` → `queue.async { runBlocking }`; inside, read stderr on the same queue (a `DataReader` with a semaphore) while stdout reads on the current thread, then `waitUntilExit`.
- **Streaming.** One pipe for stdout and stderr; `for try await line in pipe.fileHandleForReading.bytes.lines`; `withTaskCancellationHandler` whose `onCancel` terminates the process; `process.waitUntilExit()` after the loop; the caller runs `try Task.checkCancellation()` after a stream because a cancelled stream ends without throwing.
- **Recording.** Each call sends `started(command, cwd, kind)`, `output([lines])` (batched every 0.25 s for streams), `finished(exitCode, error)` to `CommandLog` through `DispatchQueue.main.async { MainActor.assumeIsolated { … } }`. The display command quotes arguments with spaces or shell characters; a multi-line argument shows as `'…script…'`.

A non-zero exit code is a result, not a throw: the caller checks `exitCode`. A cancelled stream is recorded as "Cancelled" (not a failure) and `stream` throws `CancellationError`.

Use from a store:

```swift
let result = try await shell.run("git", ["--version"], cwd: session.project.path)
guard result.exitCode == 0 else {
    activity.log("Git version", detail: result.failureMessage, outcome: .failure)
    return
}
```

`CommandLog` calls `onFailure` for a failed command that is not a `read` and not a `secret` (a missing login, for example `gh auth token`, is normal); `AppDependencies` posts `AppEvent.commandFailed`, and `OutputPanelState` opens the panel. A failing read (for example `git status` in a folder without a repository) is expected and stays hidden.

## Classification

| Kind | Examples | Output panel |
|---|---|---|
| `read` | git `status log for-each-ref rev-parse symbolic-ref reflog rev-list show-ref config diff merge-base ls-remote remote show`, `worktree list`, `stash list`, `branch` without `-d -D -m -M -u`, simctl `list get_app_container listapps bootstatus`, `spawn … read`, `du ps grep plutil pgrep`, `xcodebuild -showBuildSettings`, `gh pr view`, `gh api`, `glab api`, `osascript` without `click` | hidden unless "Show reads" |
| `action` | everything else | shown |
| `secret` | `security`, `gh auth token` | "Output hidden: it contains credentials." |
| `appLog` | `simctl spawn … log stream` | "App log lines are shown in the Logs tab only." |

## Provider protocols

One protocol per domain. Mock returns `MockData` and sleeps a little on actions. Live calls the shell and the parser.

```swift
protocol SimulatorProviding {
    func list() async throws -> [SimulatorGroup]
    func boot(udid: String) async throws
    func shutdown(udid: String) async throws
}
```

Long work returns a stream:

```swift
protocol BuildProviding {
    func schemes(projectPath: String) async -> [String]
    func run(_ request: BuildRequest) -> AsyncThrowingStream<BuildEvent, Error>
}
```

```swift
func run(_ request: BuildRequest) -> AsyncThrowingStream<BuildEvent, Error> {
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
```

The store consumes with `for try await event in provider.run(request)`, then `try Task.checkCancellation()`, then sets the final phase. `catch is CancellationError` sets `.idle`.

## Injection

`AppDependencies.init(providers:)` hands each store its provider. `AppDependencies.mock()` passes `.mock`; `.live()` passes `.live`. Collections start empty and fill in `refresh()`. `RootView` runs `.task(id: layout.openCount)` so stores refresh on each panel open.

## Rules

- Never run a command on the main actor. Provider methods are `async`; blocking work is inside `ShellRunner`.
- Destructive git commands run only after the inline confirmation. `--force` only when the item was reported dirty or locked and the confirm text said so.
- Every failure becomes an `ActivityEvent` with `.failure`; for builds also `build.phase = .failed(message)`. No silent catch.
- Exit code tolerance is explicit: `simctl boot` and `shutdown` return 149 for "already in that state"; treat it as success.
- No tests. A parser is checked once against the real output shown in the Output panel.
- Keep the mock providers working; previews and `AppDependencies.mock()` depend on them.
- A usage request reads its token for one request and drops it; the Claude token is never refreshed. A `secret` command records no output.
- No tokens through arguments. Tokens go into request headers in memory and are dropped after the request.
