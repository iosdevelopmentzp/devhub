---
name: data-layer
description: "The Data layer of DevHub: the Data folders, repositories behind Domain ports, ShellRunner (run and stream, the deadlock trap, never Process elsewhere), the command log and CommandKind classification behind the Output panel, GitCommandRunner and SimctlRunner, parsers with private DTOs, mocks in DevHubMocks, KeyValueStore persistence, Ports.live and Ports.mock wiring, injected file roots, parser and integration tests, streams for long work, threading and error rules. Load when a task runs git, xcrun, xcodebuild or any process, reads files or defaults, or adds or changes a repository."
---

# Data Layer

DevHubData implements the ports in `DevHubDomain/Repositories/`. Stores and views never see a Data type; they see
the port. DevHubMocks holds the mocks. Full rules: `docs/ARCHITECTURE.md` section 5 and `.claude/rules/data.md`.
Paths below are relative to `Packages/DevHubKit/Sources/`.

## Structure

```
DevHubData/
    Shell/          ShellRunner (package actor), ShellResult, LineBatcher, LineCollector, CommandFormatter, ISO8601
    Persistence/    UserDefaultsKeyValueStore(defaults:)
    Git/            ShellGitRepository, ShellWorktreeRepository, ShellGitChangesRepository, GitCommandRunner,
                    GitCommandEncoder, GitLogQuery, GitStatusParser, WorktreePorcelainParser, TrackingInfoParser,
                    MergedBranchesQuery; GitLab: GlabPullRequestRepository, GlabClient, Glab*Parser,
                    GlabGraphQLQueries, CodeHostErrorMapper
    Git/Parsers/    GitBranchHeaderParser, GitLogParser, GitCommitFilesParser, GitDiffOutputParser,
                    GitRefDecorationParser, GitReflogParser, GitStashParser, LocalBranchParser, RemoteBranchParser,
                    ReflogVisitParser
    GitHub/         GhPullRequestRepository, GhClient, GhPullRequestParser, GhCheckParser, GhDiffParser,
                    GhCreatedPullRequestParser, GhGraphQLQueries
    CodeHost/       RoutingCodeHostRepository (picks gh or glab per remote; see `code-host`)
    CircleCI/       CircleCIRepository(client:), CircleCIClient, CircleCIJSON, CircleCIWorkflowParser, CircleCIRunParser,
                    CircleCIJobOutputParser, CircleCITestResultParser, CircleCIFlakyTestParser, CircleCIToolStateParser
                    (the circleci CLI, ADR 006; see the pull-requests page)
    Simulators/     SimctlSimulatorRepository, SimctlAppLaunchRepository, SimctlMessagingRepository, SimctlRunner,
                    SimctlListParser, ContainerLocator, ProfileDefaultsPlan, AppURLSchemeParser,
                    Dictionary+ChildEnvironment
    Build/          XcodeBuildRepository, BuildOutputParser, BuildStepThrottle, ProductLocator, XcodeContainer
    Logs/           SimctlAppLogRepository, AppLogParser, LogRedactor, LogCounter
    Claude/         AnthropicUsageRepository, ClaudeUsageParser, ClaudeCredentialsReader, ClaudeCredentialsParser,
                    ClaudeTranscriptSessionRepository(root:), ClaudeTranscriptParser, FileReviewPromptRepository(root:)
    Copilot/        CopilotSessionRepository(root:), CopilotSessionParser, CopilotEventScanner, WorkspaceYAMLParser,
                    GitHubCopilotUsageRepository, CopilotUsageParser, CopilotTokenReader, CopilotTokenParser
    AI/             CompositeAISessionRepository (Claude and Copilot sessions in one list),
                    ShellAITextRepository(shell:folder:home:) (one-shot `claude -p` or `copilot -p`, prompt in a temporary file)
    Config/         FileConfigRepository(home:pollInterval:), ConfigFolderReader, ConfigWatcher, ExampleConfigWriter,
                    ShellScriptRunner
    Network/        NetworkRequestRedactor
    Network/MockServer/  NWMockServerRepository(session:) (actor, one LocalMockServer per udid), LocalMockServer
                    (NWListener on 127.0.0.1), HTTPRequestParser, MockHTTPRequest, MockHTTPResponse,
                    HTTPResponseSerializer, HTTPForwarder (URLSession, no redirects), MockExchangeHandler,
                    URLSession+MockForwarding   (Network.framework allowed here only)
    Network/MockSets/    FileMockSetRepository(root:), MockSetFileCoder, MockRouteName
    Workspace/      ShellWorkspaceOpener, AccessibilityXcodeAttacher, XcodeDerivedDataRepository, XcodeProjectDetector,
                    PathToolLocator, SystemUserNotificationRepository, GlobalHotKey, GlobalShortcut+Carbon,
                    Notification+GlobalHotKey, PlistReader, LaunchOutput, FileManager+ModificationDate
                    (AppKit allowed here only)
    Disk/           XcodeDiskCleanupRepository(shell:home:derivedDataRoot:), DiskFolderScanner, SimctlRuntimeListParser,
                    SimctlUnavailableDeviceParser
    Assembly/       Ports+Live.swift
DevHubMocks/        Mock<Thing>Repository one per file, MockData and MockData+<Domain>.swift,
                    Persistence/InMemoryKeyValueStore, Ports+Mock.swift
```

`Ports.live(shell:)` (`DevHubData/Assembly/Ports+Live.swift`) builds every repository once and passes the real file
roots (`~/.claude/projects`, `~/.copilot/session-state`, `~/.devhub/mocks`, `~/.devhub/prompts`). `Ports.mock()` (`DevHubMocks/Ports+Mock.swift`)
builds every mock. `UseCases(ports:)` builds the use cases. `AppContainer.init()` (DevHubComposition) builds the
`ShellRunner` and the `CommandLog`.

Module rules: every Data and Mocks file imports `DevHubDomain`. Nonisolated is the module default, so no type says
`nonisolated`. Repositories, runners and parsers stay internal; `package` only on `Ports.live`,
`ShellRunner.init(recorder:)`, `UserDefaultsKeyValueStore.init(defaults:)` and `GlobalHotKey`. In Mocks, `MockData`
statics, `InMemoryKeyValueStore` and `Ports.mock` are `package`; the mock types stay internal.

## Add a repository

1. Port in `DevHubDomain/Repositories/<Thing>Repository.swift`:

```swift
package protocol DeviceRepository: Sendable {
    func list() async throws -> [Device]
    func reconnect(id: String) async throws
}
```

2. Live type in `DevHubData/<Domain>/<Technology><Thing>Repository.swift` (internal):

```swift
struct SimctlDeviceRepository: DeviceRepository {
    let simctl: SimctlRunner

    init(shell: ShellRunner) {
        simctl = SimctlRunner(shell: shell)
    }

    func list() async throws -> [Device] {
        let result = try await simctl.run(["list", "devices", "-j"], failure: DeviceError.command)
        return try DeviceListParser.parse(result.stdout)
    }
}
```

3. Parser in its own file (`DeviceListParser.swift`), pure, with a private DTO.
4. Mock in `DevHubMocks/Mock<Thing>Repository.swift` returning `MockData` and sleeping a little on actions.
5. Spy in `DevHubTestSupport/Spy<Thing>Repository.swift` (see `/testing`).
6. One field in `Ports` and its `package init`, one line each in `Ports.live(shell:)`, `Ports.mock()`, `PortSpies`
   and `Ports.spies()`. The store receives `ports.<field>` in `PresentationAssembly`.
7. Tests: a parser suite with a fixture in `Tests/DevHubDataTests/`; an integration suite when the repository runs
   git or `sh` (see below).

A repository takes what it needs in `init` (`ShellRunner`, another port, a `KeyValueStore`). No repository builds
another repository; `Ports.live` passes it in. A file root is an `init` parameter, so a test can pass a
`TemporaryDirectory`. No `.shared`.

## ShellRunner

Every process in the app goes through `ShellRunner` (`DevHubData/Shell/ShellRunner.swift`). Never `Process` in another
file (`Scripts/check-layers.sh` fails on it), never a process on the main actor. `AppContainer.init()` builds one
runner with `ShellRunner(recorder: CommandLogRecorder(log: commandLog))` and passes it to `Ports.live(shell:)`.

```swift
package actor ShellRunner {
    package init(recorder: any CommandRecording)
    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?) async throws -> ShellResult
    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String]) async throws -> ShellResult
    func stream(_ executable: String, _ arguments: [String], cwd: String?, onLine: @escaping @Sendable (String) -> Void) async throws -> Int32
    func stream(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String], onLine: @escaping @Sendable (String) -> Void) async throws -> Int32
}
```

- Launches through `/usr/bin/env <executable>`, puts `/opt/homebrew/bin:/usr/local/bin` in front of `PATH`, merges
  the extra environment, expands `~` in `cwd`.
- `run` throws only when the process cannot start. A non-zero exit comes back in `ShellResult.exitCode`; the caller
  decides. `ShellResult.failureMessage` is stderr, else stdout, else "Exited with code N.".
- **The deadlock trap.** Never read process output with a blocking call (`readDataToEndOfFile()`,
  `waitUntilExit()`) on the Swift concurrency pool or on a GCD queue. A concurrent GCD queue has at most 64 threads;
  when every thread waits for a stderr reader that is queued behind it, all later commands hang until a restart.
  `run` uses `ProcessOutput` (`Shell/ProcessOutput.swift`): `readabilityHandler` on both pipes and a
  `terminationHandler`, so no thread waits. `manyParallelRunsAllFinish` in `ShellRunnerIntegrationTests` guards it.
- **Streaming.** One pipe for stdout and stderr; `ProcessLines.lines(of:)` (`Shell/ProcessLines.swift`) turns the pipe into an
  `AsyncStream<String>` through `readabilityHandler`, so no cooperative thread waits on the pipe (`FileHandle.bytes.lines` did, and
  starved the store tests on a 3-core CI runner); `withTaskCancellationHandler` whose `onCancel` terminates the process. After a stream the caller runs
  `try Task.checkCancellation()`: a cancelled stream ends without throwing.
- No token in arguments. A token goes into a request header in memory and is dropped after the request.

## Command log and the Output panel

Every `run` and `stream` reports `started`, `output` (batched every 0.25 s by `LineBatcher` for streams) and
`finished` as a `CommandEvent` to the `CommandRecording` port (`DevHubDomain/Repositories/`).
`CommandLogRecorder` (DevHubPresentation `Shared/`) hops to the main queue and feeds `CommandLog`, which the Output
panel shows. `CommandLog` keeps 300 entries and 4 000 lines per entry. `CommandFormatter.displayCommand` quotes
arguments with spaces or shell characters.

`CommandKind.classify(_:_:)` (Domain) decides how an entry shows:

| Kind | Examples | Output panel |
|---|---|---|
| `read` | git `status log for-each-ref rev-parse symbolic-ref reflog rev-list show-ref config diff merge-base ls-remote remote show`, `worktree list`, `stash list`, `branch` without `-d -D -m -M -u`; simctl `list get_app_container listapps bootstatus`, `spawn … read`; `du ps grep plutil pgrep`; `xcodebuild -showBuildSettings`; `gh` and `glab` reads (below); `osascript` without `click` | hidden unless "Show reads" (`OutputPanelState.showsReads`) |
| `action` | everything else | shown |
| `secret` | `security`, `gh auth token` | "Output hidden: it contains credentials." Nothing recorded |
| `appLog` | `simctl spawn … log stream` | "App log lines are shown in the Logs tab only." Nothing recorded |

`gh` and `glab` share one rule (`codeHostKind`): a GraphQL query is a `read`, a GraphQL mutation an `action`; an
`api` call with `-X GET` is a `read`, with another method an `action`; an `api` call without a method is a `read`
unless it sends fields (`-f -F --field --raw-field --input`); the subcommands `view list checks diff status` are
reads. `gh auth token` is `secret`.

A new command that only reads belongs in the `read` list, with a line in `CommandKindTests`.

When an action fails, the store logs it to `ActivityLog` and may post `AppEvent.commandFailed`; `OutputPanelState`
opens the Output panel only when "Open When a Command Fails" is on. A failed read (for example `git status` in a
folder without a repository) is expected and stays hidden.

`ShellRunner` puts `OperationScope.current` (a Domain `@TaskLocal` UUID) into the `started` event of every command.
`ActionRunner` and `ConfigActionsStore` set it with `OperationScope.$current.withValue(id)`, so the commands of one
action form the steps of its operation card (`OperationLog`, `OperationCardMapper`). A command started from a
`Task.detached` loses the ID; a plain `Task {}` and an `AsyncThrowingStream` build closure keep it.

## Shared runners

| Helper | Use |
|---|---|
| `GitCommandRunner(shell:)` | `run(arguments, in:, environment:) -> String` throws `WorktreeError.command(failureMessage)` on a non-zero exit; `result(...)` for the raw `ShellResult` |
| `GitCommandEncoder` | the one `switch` from `GitCommand` (Domain) to arguments and environment. A new git action is a new `GitCommand` case plus one `case` here |
| `SimctlRunner(shell:)` | `run(arguments, allowingExit: [149], failure: SimulatorError.command)`; `xcrun simctl` is prepended; tolerated exit codes are explicit |
| `GhClient(shell:)`, `GlabClient(shell:)` | `gh api` and `glab api` calls (REST and GraphQL) for the code host repositories; see `code-host` |
| `PlistReader.dictionary(at:)` | plist file to `[String: Any]?` |
| `ISO8601.date(from:)` | fractional seconds first, then plain |
| `TrackingInfoParser`, `MergedBranchesQuery` | upstream, ahead and behind from `for-each-ref`; the set of branches merged into the base; both git repositories use them with `MergedBranchPolicy` |

## Parsers and DTOs

A parser is a pure type in its own file: text in, values out (`SimctlListParser`, `WorktreePorcelainParser`,
`GitStatusParser`, `Git/Parsers/GitLogParser`, `BuildOutputParser`, `AppLogParser`, `GlabPullRequestParser`,
`ClaudeTranscriptParser`, `HTTPRequestParser`). A parser never reads the clock: it takes `now` or `date` as a parameter
(`ClaudeUsageParser.parse(_:plan:now:)`). A repository reads the file or runs the command and calls the parser. A `Decodable` DTO for JSON or plist
output is `private` to its parser or repository. A Domain model is never `Decodable` for an external format: map
DTO → model in the parser. A parser is checked once against the real output shown in the Output panel, then pinned with a fixture test
(`Tests/DevHubDataTests/Fixtures/<Thing>Fixture.swift`).

## Long work

A port method that runs for a long time returns a stream or takes an `onEvent` closure:

```swift
func build(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws -> [String]
```

The use case (`BuildAndRunUseCase`) wraps the sequence in an `AsyncThrowingStream` with a `Task` inside and
`continuation.onTermination = { _ in task.cancel() }`, so cancelling the consuming task terminates the process.
The store consumes with `for try await event in useCase.run(request)`, then `try Task.checkCancellation()`.

## Mock server

`NWMockServerRepository: MockServerRepository` (an actor) keeps one `LocalMockServer` per simulator UDID. Each
server is an `NWListener` bound to `127.0.0.1` (`acceptLocalOnly`). It first tries a stable port for the simulator:
`MockServerPortPolicy.port(for: udid)` (Domain) hashes the UDID to a port from 49152 to 59151, so the app keeps the
same base URL after a restart of DevHub. When that port is busy, the server starts again on any free port. A second `start` for the
same UDID keeps the port and swaps the upstream, the rules and the callback; `update(udid:rules:)` swaps only the
rules; `stop` cancels the listener and every open connection. Network.framework is allowed only in
`DevHubData/Network/MockServer/` (`check-layers.sh`).

- One request per connection. `HTTPRequestParser.parse(_:)` is pure: request line, headers, body by
  `Content-Length`; `.incomplete` until the last byte; chunked bodies get 501 unless the body is the empty
  `0\r\n\r\n`. Every answer goes through `HTTPResponseSerializer` with a correct `Content-Length` and
  `Connection: close`, then the connection closes.
- `MockExchangeHandler` decides: a WebSocket upgrade gets 501 and an exchange with the error "WebSocket not mocked
  yet"; otherwise `MockRuleMatcher` (Domain) picks the first enabled rule. A respond rule never touches the network.
  A patch rule forwards, waits the delay, then runs `JSONPatcher` (Domain) when the body is JSON. No rule: forward.
  An upstream failure becomes 502 with a JSON error body.
- `HTTPForwarder` builds `upstream + target`, copies method, body and the app's headers (with `Authorization`,
  which the real API needs), drops `Host`, `Connection`, `Accept-Encoding`, `Content-Length` and hop-by-hop
  headers, sends `Accept-Encoding: identity`, and never follows redirects (a task delegate returns `nil`). From the
  answer it drops `Content-Encoding`, `Transfer-Encoding`, `Content-Length` and hop-by-hop headers. The session is
  injected: `URLSession.mockForwarding()` (ephemeral, no cookies, no cache) in `Ports.live`, a `URLProtocol` stub in
  tests (`StubURLProtocol` in `DevHubDataTests/Support/`).
- Every exchange becomes a `NetworkRequest` with `mockRuleID` and request headers, and goes through
  `NetworkRequestRedactor` before `onExchange` is called. The Network tab lists exchanges only.
- The launch side lives in Domain: `MockLaunchEnvironment.variables(port:variable:)` puts the server URL into
  `network.baseURLVariable`, `MockUpstreamPolicy` takes the upstream from the launch profile. Every launch goes
  through `SimulatorRepository.launch` with the environment and arguments of a `LaunchPlan`; Data prefixes every
  key with `SIMCTL_CHILD_` (`Dictionary+ChildEnvironment`). `SimctlAppLaunchRepository` reads the installed app
  (version, identity hook in the binary, stored profile) and does the clean install.
- `FileMockSetRepository(root:)` stores `<root>/<project folder>/<set name>.json` with `JSONSerialization` (rules
  with inline JSON patch values). Respond bodies over 1 KB go to `<set>/bodies/GET_v1_settings_list.json`
  (`MockRouteName`, the UI-test fixture naming). `MockSetFileCoder` masks bodies and patch values with
  `LogRedactor` and drops credential headers before writing. A broken file throws `MockSetError.unreadable` with
  its name. Default root `~/.devhub/mocks` from `Ports.live`.
- Tests: `HTTPRequestParserTests`, `HTTPResponseSerializerTests`, `HTTPForwarderTests`, `MockExchangeHandlerTests`
  (stub session), `FileMockSetRepositoryTests` (round trip, body files, "no token on disk"), and
  `MockServerIntegrationTests` over real sockets (`RawHTTPClient` for raw requests such as a WebSocket upgrade).

## Persistence

`KeyValueStore` (Domain) is the only way to `UserDefaults`. `UserDefaultsKeyValueStore(defaults: .standard)` in the
app (tests pass `UserDefaults(suiteName:)`), `InMemoryKeyValueStore` (DevHubMocks) in previews and tests. Typed getters and setters plus `decode(_:forKey:)` / `encode(_:forKey:)`
(JSON). Keys are string constants next to their owner (`private enum Keys` in the store, `PreferenceKeys` for the
app-wide ones). Never change a key name: saved data would be lost.

## Rules

- Never run a command on the main actor. Data is nonisolated by module default; a type that needs state is an `actor`.
- Never `Process` outside `ShellRunner`.
- Every failure becomes a domain error with a user-facing message; raw stderr goes into the `.command(String)`
  case, trimmed. No silent `catch`: a swallowed error is a `nil` or an empty list only when the port says so.
- Secrets: a token is read for one request and dropped; `security` output is never recorded; app log lines pass
  through `LogRedactor` before they leave the repository; nothing of that is written to disk.
- Keep the mocks working: previews and `PresentationAssembly.preview()` depend on them.
- Destructive git or simctl commands run only after the inline confirmation in the row.

## Tests

- Unit tests in `Packages/DevHubKit/Tests/DevHubDataTests/<Folder>/`, mirroring `Sources/DevHubData/`.
- Parsers and encoders: fixture text in, exact values out. `GitCommandEncoder` tests pin the argument list per case.
- File-bound code (`FileMockSetRepository`, `ClaudeTranscriptSessionRepository`, `PlistReader`,
  `XcodeContainer`): build the files in a `TemporaryDirectory` and pass its URL.
- Integration suites in `DevHubDataTests/Integration/` run real processes. Name `<Type>IntegrationTests`, attribute
  `@Suite(.tags(.integration))`. `TemporaryGitRepository` (`DevHubDataTests/Support/`) builds a repository with
  `git init`, commits, branches (`feature`, `merged-branch`) and a linked worktree, and records commands with
  `SpyCommandRecorder`.

```swift
@Suite(.tags(.integration)) struct ShellWorktreeRepositoryIntegrationTests {
    @Test func listsTheMainCheckoutAndTheLinkedWorktree() async throws {
        let repo = try await TemporaryGitRepository()
        let worktrees = try await ShellWorktreeRepository(shell: repo.shell).list(projectPath: repo.path)

        #expect(worktrees.map(\.path).contains(repo.linkedPath))
    }
}
```

Run `Scripts/test.sh --filter DevHubDataTests`, or `Scripts/test.sh --skip integration` to leave out the process
suites.
