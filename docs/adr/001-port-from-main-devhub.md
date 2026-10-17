# DevHubGeneric: rewrite on the package architecture and port every feature of the main DevHub

Status: ready for implementation (written 2026-10-17 by the planning session, decisions confirmed with the user). The implementing session copies this file to `docs/adr/001-port-from-main-devhub.md` in milestone M0 (replace the two absolute paths in section 1 with `<main repository>` and `<this repository>`: the ADR must not name a person or a machine path) and keeps a step log at its end (one row per commit: hash, what it did).

## 1. Context

Two repositories exist on this machine:

| Repository | Path | What it is |
|---|---|---|
| Main DevHub | `<main repository>` | The working daily tool. 1,110 files, local Swift package `Packages/DevHubKit` with six modules, Swift 6, about 1,580 Swift Testing tests. Many parts are tied to one company project (names, hosts, branch names, plist suites, environment variables, a session log format). |
| DevHubGeneric | `<this repository>` | The MVP of a generic hub built from the seed in `DevHub/docs/generic-hub/`. 325 files, one Xcode target, Swift 5 mode, no tests. It has what the main app lacks: the `.devhub/` config system (actions, scripts with headers, placements, launch profiles, custom tabs, line protocol), Copilot sessions and usage, projects list. It lacks the Build & Run, Pull Requests, Network, Identity, and the Git extras of the main app. It is not a git repository yet. |

Goal: DevHubGeneric becomes the one app. It gets the architecture and every feature of the main DevHub, but nothing project-specific in code or docs. Project knowledge lives in `.devhub/` config layers. GitHub (`gh`) is the primary code host; GitLab (`glab`) stays as the second one behind the same protocol.

The implementation is delegated to another session (Opus). This document is the full brief for that session.

## 2. Decisions already taken with the user (2026-10-17)

1. Architecture: local Swift package with modules `Domain / Data / Mocks / UI / Presentation / Composition / TestSupport`, Swift 6 language mode, same rules as `DevHub/docs/ARCHITECTURE.md`.
2. Tests: Swift Testing with spies, like the main app. Every parser, policy, use case, mapper and store action gets a test.
3. Features ported in a generic form: Network monitor + mock server, Device identity as "launch identities", GitLab next to GitHub. Slack commands are NOT ported (a config action with `{ "open": ... }` or a script covers that need).
4. Plan language: English. The plan is copied into the repository as `docs/adr/001-port-from-main-devhub.md` in the first commit.
5. Code host: GitHub first (`gh`), GitLab second (`glab`), one protocol, chosen by the remote URL.
6. Base of the result: a copy of the main app's package `Packages/DevHubKit` (tests included), anonymised, into which the generic app's config system, Copilot support, debug switches, skills and docs are grafted. The generic app's own Swift code is the port source for those parts only. Git history starts fresh in DevHubGeneric (the main repository's history names the owner's project).
7. GitHub: the user runs `gh auth login` once. The implementing session creates two private repositories with `gh repo create`: one for DevHubGeneric (remote `origin`) and one playground for pull request checks.
8. Documentation is a deliverable (section 9): architecture, spec, schema, one page per feature, ADRs with step logs, status, changelog, skills, rules. Plain English.

## 3. Inventory: what exists where (facts, 2026-10-17)

### 3.1 Main DevHub (source of features)

Package `Packages/DevHubKit`, Swift 6, macOS 26.4, `MemberImportVisibility`, `InferIsolatedConformances`, `NonisolatedNonsendingByDefault`. Tabs: Home, Git, GitLab, Worktrees, Simulators, Logs, Network, Claude, Slack, Settings, Usage strip, Output. Tests: about 1,580 in `Tests/` (Domain, Data with integration suites, UI, Presentation). Rules in `docs/ARCHITECTURE.md`, `.claude/rules/*.md`, `Scripts/check-layers.sh` (runs inside `build.sh`), `Scripts/test.sh`.

Project-specific code (must not be copied as is):

| Where | What | Generic replacement |
|---|---|---|
| `DevHubComposition/AppContainer.swift:43-44` | default project path | none: projects list from settings |
| `DevHubDomain/Values/BranchName.swift:4` | `defaultBaseRef` is the owner's base branch | `git.baseBranch` from config, fallback `origin/HEAD`, then `origin/main` |
| `DevHubDomain/Policies/BranchCleanupPolicy.swift:4` | protected names `dev, main, master` | `git.protectedBranches` from config plus the base branch |
| `DevHubDomain/Policies/MergeRequestTargetPolicy.swift:4` | preferred targets `dev, develop, main, master`, `dev` first | `git.pullRequests.targets` from config; base branch first |
| `DevHubDomain/Policies/TicketPrefix.swift` | regex `^[A-Z][A-Z0-9]+-\d+`, `KEY: ` | `git.commitPrefix.pattern` and `format` (already in the generic schema) |
| `DevHubDomain/Models/DeviceIdentityConfig.swift:36-51` | one preset: bundle ID, plist suite, API hosts, env names | `launch.identities` and `network.environments` in config (section 5) |
| `DevHubData/Simulators/SessionLogParser.swift`, `SessionLogReader.swift`, `DevHubData/Network/SessionLog*.swift` | the app's own log file format | dropped; the mock server is the only network source; "actual state" comes from a config script |
| `DevHubDomain/Models/Slack*.swift`, `DevHubData/Slack/`, `DevHubPresentation/Features/Slack/` | Slack commands | dropped (decision 3) |
| `DevHubPresentation/Shared/SlackMessageText.swift`, "Copy for Slack" | message format `!iid title\nurl` | kept as "Copy link with title" |
| `DevHubPresentation/Simulators/MessagingStore.swift:36,95` | deep link schemes, app name | `simulators.deepLinks` examples from config, recent links in preferences |
| `DevHubPresentation/Build/Models/BuildState.swift` | default scheme name | detected scheme |
| `ShellWorktreeRepository` | worktree folder `.claude/worktrees`, `init.sh`, `.worktreeinclude` | `git.worktrees.folder`, `bootstrap`, `include` from the generic schema |
| `GlabClient` | throws on a host that contains `github` | code host protocol (section 6) |
| `ShellGitRepository.templatePath` | `.gitlab/merge_request_templates/Default.md` | per host default, overridable |
| Settings help text, placeholders, previews, mocks, about 110 test fixtures | the owner's product name, ticket keys, deep link schemes, base branch, repository URL | `Example App`, `ABC-123`, `example://`, `origin/main`, `github.com/example/app` |

### 3.2 DevHubGeneric (target repository, today)

One target, 279 Swift files, 17,066 lines, Swift 5 mode, no tests, not a git repository. Tabs: Home, Git, Worktrees, Simulators, Logs, AI, Settings.

What it has that the main app lacks (must survive the rewrite):

- `.devhub/` config in three layers (project, user, global) with watcher and hot reload: `project.json`, `actions/*.json`, `scripts/*` with `# devhub:` headers, `tabs/*.json` (decoded, not rendered). Schema in `docs/extensions.md`. Code: `DevHub/Core/Config/*`, `Shared/ConfigStore*`, `Shared/ActionCatalog`, `Shared/ActionRunner*`, `Shared/ActionContextBuilder`, `Core/Parsers/PlaceholderExpander`, `ScriptDirectiveParser`, `ScriptHeaderParser`, `Services/Config/*`.
- Actions with inputs (`text`, `number`, `toggle`, `choice`, `branch`, `worktree`, `simulator`, `scheme`, `file`, `folder`), placements, `confirm`, `refresh`, `when`, context variables `DEVHUB_*`, the `@devhub` line protocol (`progress`, `toast`, `copy`, `open`, `notify`, `refresh`, `error`, `app`, `view`).
- Launch profiles (`env`, `args`, `defaults`, `cleanInstall`), `kind: command` projects, `simulators.statusScript`, `home.quickActions` order.
- Copilot CLI sessions and Copilot usage next to Claude (`Core/Parsers/Copilot*`, `Services/AI/*`).
- Debug launch switches for headless checks (`App/DebugLaunch*.swift`, `DebugGitOps.swift`): `DEVHUB_OPEN_PANEL`, `DEVHUB_TAB`, `DEVHUB_SNAPSHOT`, `DEVHUB_BUILD_RUN`, `DEVHUB_GIT_OPS`, and more (listed in the `build-and-run` skill).
- PR line through `gh pr view --json` and `glab api` (`Services/Git/LivePullRequestProvider`).
- Skills under `.github/skills/` (symlinked from `.claude/skills/`), hooks for Copilot and Claude, `Scripts/smoke.sh`.

Known gaps in its Build & Run (from the code, not the docs): clean install never resets the keychain; a branch without a checkout cannot be built (no worktree creation); the cached `.app` is never used; run options are global, not per simulator; `open -a Simulator` is never called; shut-down simulators have no container scan and no plist fallback; "Show log" writes the error only; schemes come from `xcshareddata` only; the container path is relative and so DerivedData matching never works; `LaunchProfile.cleanInstall` is unused; `RunPlan.swift` is dead; `SampleDataBanner` is unused; custom tabs are decoded but never rendered; no command palette; no launch at login; no Doctor.

## 4. Target architecture

Same modules, names and rules as the main app, so files move between the two repositories with their imports intact:

```
DevHubGeneric/
  DevHub.xcodeproj                 app target DevHub (links DevHubComposition), Swift 6, macOS 26.4
  DevHub/DevHubApp.swift, Assets.xcassets
  Packages/DevHubKit/
    Package.swift                  copy of the main app's file
    Sources/DevHubDomain           models, values, ports, policies, use cases, errors, Assembly/
    Sources/DevHubData             Shell/ Persistence/ Git/ CodeHost/ Simulators/ Build/ AI/ Logs/ Network/ Config/ Workspace/ Assembly/
    Sources/DevHubMocks
    Sources/DevHubUI
    Sources/DevHubPresentation     Shared/ Shell/ Features/<Name>/{Store, Models/, Views/}
    Sources/DevHubComposition      AppContainer, DebugLaunch (headless switches)
    Sources/DevHubTestSupport
    Tests/DevHubDomainTests DevHubDataTests DevHubUITests DevHubPresentationTests
  Scripts/                         build.sh (runs check-layers.sh and check-anonymous.sh), test.sh, run.sh, install.sh, smoke.sh, make-launcher.sh, ai/
  docs/                            ARCHITECTURE.md, SPEC.md, STATUS.md, extensions.md, adr/, examples/devhub/, features/
  .github/skills, .claude/skills (symlink), .claude/rules, .claude/hooks (or Scripts/ai)
```

Copy these files from the main repository without change, then adjust names: `Package.swift`, `Scripts/check-layers.sh`, `Scripts/test.sh`, `Scripts/build.sh`, `docs/ARCHITECTURE.md`, `.claude/rules/{layers,domain,data,presentation,testing}.md`, the skills `add-use-case`, `data-layer`, `testing`. Keep from the generic repository: `extensions`, `providers-and-shell` (rewritten as `data-layer` notes on config), `build-and-run` (debug switches), `panel-window`, `ui-components`, `xcode-toolchain`, `update-docs`, `add-feature` (merge both versions).

Where the generic-only code lands in the modules:

| Generic file (today) | Module and new name |
|---|---|
| `Core/Config/ProjectConfig.swift`, `ActionConfig.swift`, `ConfigModels.swift` | `DevHubDomain/Models/Config/` (`ProjectConfig`, `ActionConfig`, `ActionInput`, `Placement`, `LaunchProfile`, `TabConfig`, `ResolvedConfig`), one type per file |
| `Core/Config/ConfigMerge.swift` | `DevHubDomain/Policies/ConfigMergePolicy.swift` |
| `Core/Config/ConfigDecoding.swift`, `Services/Config/LiveConfigProvider.swift`, `ConfigWatcher.swift` | `DevHubData/Config/FileConfigRepository.swift`, `ConfigDecoder.swift`, `ConfigWatcher.swift`; port `ConfigRepository` in Domain |
| `Core/Config/ExampleConfig.swift`, `ExampleScripts.swift` | `DevHubData/Config/ExampleConfigWriter.swift` (strings generated from `docs/examples/devhub/` by `Scripts/generate-example-config.sh`) |
| `Core/Parsers/ScriptHeaderParser`, `ScriptDirectiveParser`, `PlaceholderExpander` | `DevHubData/Config/` parsers; `PlaceholderExpander` is a Domain policy (pure) |
| `Shared/ActionCatalog`, `ActionRunner*`, `ActionContextBuilder`, `ConfigStore*` | `DevHubPresentation/Features/ConfigActions/ConfigActionsStore.swift` (+ `Execution`, `Directives`), `DevHubPresentation/Shared/ConfigStore.swift`, plus the Domain policies `ActionCatalogPolicy`, `ActionContextPolicy`, `EffectiveProjectPolicy` (Appendix B) |
| `Core/Parsers/Copilot*`, `Services/AI/*` | `DevHubData/AI/CopilotSessionRepository.swift`, `CopilotUsageRepository.swift`, next to the Claude ones from the main app; one `AISessionRepository` port with a `provider` field |
| `App/DebugLaunch*.swift`, `DebugGitOps.swift` | `DevHubComposition/Debug/` |
| `Services/Git/LivePullRequestProvider` | replaced by section 6 |

Naming follows the main app: ports `*Repository`, live `<Technology><Thing>Repository`, mocks `Mock*`, spies `Spy*`, stores `<Feature>Store`, row models and mappers. The generic word "provider" disappears.

## 5. Anonymity rules and the config schema additions

### 5.1 Rules (checked by `Scripts/check-anonymous.sh`, run by `build.sh`)

1. No company, product, host, bundle ID, plist suite, branch name, ticket prefix, deep link scheme or person name from the owner's projects anywhere under the repository: code, tests, previews, mocks, docs, changelog, status, ADRs, skills, commit messages.
2. Sample data uses one vocabulary: project `Example App`, bundle `com.example.app`, suite `group.com.example.app`, ticket `ABC-123`, branches `main`, `feature/ABC-123-short-title`, remote `github.com/example/app`, deep link `example://`, people `alex`, `sam`.
3. Allowed hosts in code: `github.com`, `api.github.com`, `gitlab.com`, `api.anthropic.com`. Every other host comes from config or from the remote URL.
4. Default branch names allowed in code: none as a hard value. The base branch is `origin/HEAD`, then `origin/main`. The protected list defaults to the base branch plus `main`, `master`, `develop`, `dev` (common names, not project names).
5. The script greps for the forbidden words. The list of the owner's own words is NOT in the repository: the script reads `~/.devhub/anonymity-denylist.txt` when it exists (one word per line, case-insensitive) and always checks the built-in patterns (a `com.` bundle ID that is not `com.apple.` or `com.example.`, an `https://` host that is not in rule 3, a `group.` suite that is not `group.com.example`). The user creates the denylist file once before the first commit.
6. The docs that come from the main app (`docs/ARCHITECTURE.md`, ADR texts, STATUS decisions) are rewritten, not copied: every decision that names the owner's project is either generalised or left out.

### 5.2 New and changed fields in `docs/extensions.md`

All optional. Defaults are detected or neutral.

| Field | Type | Default | Effect |
|---|---|---|---|
| `git.remote` | string | `origin` | the remote every git command uses |
| `git.baseBranch` | string | `<remote>/HEAD`, else `<remote>/main` | unchanged |
| `git.protectedBranches` | [string] | `["main", "master", "develop", "dev"]` plus the base | never offered for delete or bulk cleanup |
| `git.commitPrefix.pattern`, `format` | regex, string | `^([A-Z][A-Z0-9]+-\d+)`, `$1: ` | unchanged; the same pattern finds the ticket key for the chip |
| `git.ticketURL` | string | — | `{key}` placeholder; the ticket chip opens it; empty means the chip copies the key |
| `git.host.kind` | `github` \| `gitlab` | detected from the remote URL (`github` when the host contains `github`, `gitlab` when it contains `gitlab`, else `github` if `gh auth status` lists the host, else `gitlab`) | which CLI and API shape the Pull Requests tab uses |
| `git.host.name` | string | host of the remote URL | passed to `gh --hostname` / `glab --hostname` |
| `git.pullRequests.targets` | [string] | base branch, then `develop`, `main`, `master` | order of the target picker in the new request form |
| `git.pullRequests.template` | path | `.github/pull_request_template.md` (GitHub) or `.gitlab/merge_request_templates/Default.md` (GitLab) | description template of a new request |
| `git.pullRequests.staleDays` | number | 14 | the `stale` tag |
| `git.pullRequests.defaults` | `{ "draft": bool, "deleteSourceBranch": bool, "squash": bool }` | `false, true, false` | form defaults |
| `git.fetchOnOpenMinutes` | number | 0 (off) | moves from Settings to config (per project), Settings keeps a global default |
| `ai.reviewCommand` | string | `claude "$(cat {prompt})"` | "Fix threads with AI": the command run in the terminal inside the worktree; `{prompt}` is the prompt file |
| `launch.profiles[].storage` | `{ "suite", "key" }` | — | the plist suite and key in the app's data container where the app keeps its selected profile; lets DevHub read back which profile the installed app uses |
| `launch.profiles[].upstream` | https URL | — | the real API host for the mock server passthrough when the app runs with this profile |
| `launch.profiles[].production` | bool | false | red tint, refuses the mock server, confirms before launch |
| `launch.identity` | `{ "variable", "keptVariable", "args": [], "idPrefix", "cleanInstallOnChange", "hookMarker" }` | — | section 7.6; absent means no identity controls |
| `simulators.statusScript` | path | — | unchanged, plus the new `state` directive (section 7.6) |
| `simulators.deepLinks` | [string] | `[]` | example links shown in the Send popover before any recent link exists |
| `network.baseURLVariable` | string | — | the environment variable the app reads for its API base URL; empty hides the mock server UI |
| `network.mocksFolder` | path | `~/.devhub/mocks/<project folder name>` | where mock sets live |
| `home.quickActions` | | | unchanged, plus new built-ins `builtin.newPullRequest`, `builtin.pullRequests` |

Placements gain `pullRequests.row` (context `DEVHUB_PR_NUMBER`, `DEVHUB_PR_URL`, `DEVHUB_BRANCH`) and `network.toolbar`. Refresh targets gain `pullRequests` and `network`. `when` gains `{ "host": "github" | "gitlab" }`. Context variables gain `DEVHUB_PROFILE` (selected launch profile id), `DEVHUB_APP_CONTAINER`, `DEVHUB_DATA_CONTAINER` (status script only) and `DEVHUB_HOST` (`github` or `gitlab`).

The line protocol gains `{"state": {"identity": "…", "profile": "…", "host": "…", "user": "…"}}` (status script only, section 7.6).

## 6. Code host protocol (GitHub first, GitLab second)

One Domain port, two Data implementations, chosen per project by `CodeHostDetector`.

```
DevHubDomain/Models/CodeHost/
  CodeHostKind            github, gitlab
  CodeHostDescriptor      kind, host, projectPath, requestNoun ("Pull Request" / "Merge Request"), referencePrefix ("#" / "!"), webLinks (branch, compare, commit, request, newRequest)
  CodeHostCapabilities    canRevokeApproval, canRebaseFromAPI, hasAutoMerge, hasRetryChecks, hasCancelChecks, hasLabels, hasDraft, hasSquashChoice, hasDeleteSourceChoice, supportsReviewThreads
  PullRequestSummary      number, title, state (open, draft, merged, closed), author, sourceBranch, targetBranch, url, createdAt, updatedAt, mergedAt, closedAt, mergedBy, hasConflicts, readiness (MergeReadiness), approvals [String], myReview (none, approved, changesRequested), openThreads, resolvedThreads, additions, deletions, files, commits, behindTarget, checks (CheckSummary), labels, autoMerge, permissions (canMerge, canApprove), headSHA, squashOnMerge, deleteSourceOnMerge
  MergeReadiness          mergeable, conflicts, needsApproval, checksPending, checksFailed, needsRebase, draft, blocked, unknown
  CheckSummary            status (success, failure, running, pending, cancelled, skipped, none), failedCount, url, duration, failedJobs [CheckJob]
  PullRequestDetails      description, failedJobs, threads [ReviewThread]
  ReviewThread            id, path, line (new, old), author, body, replies, resolved, url
  PullRequestFileDiff     (same as MergeRequestFileDiff today)
  PullRequestQuery        scope (mine, toReview, assigned, all), state (open, merged, closed, all), after cursor
  PullRequestList         items, hasMore, cursor, total
  NewPullRequest          source, target, title, body, draft, deleteSource, squash, labels
DevHubDomain/Repositories/
  CodeHostRepository      descriptor(projectPath) ; capabilities ; status(branch) ; list(query) ; details(number) ; diffs(number) ; approve ; revokeApproval ; setDraft ; updateBranch (rebase) ; retryChecks ; cancelChecks ; merge(number, squash, deleteSource) ; setAutoMerge ; cancelAutoMerge ; create ; labels ; resolveThread ; reply
DevHubData/CodeHost/
  CodeHostDetector        remote URL + config override -> CodeHostDescriptor
  GhClient                `gh --hostname <h> api …`, `gh api graphql -f query=… -F var=…`, `gh pr …`; errors: exit 127 -> notInstalled("brew install gh"), 401 / "auth" -> notLoggedIn("gh auth login --hostname <h>")
  GhPullRequestRepository + GhGraphQLQueries + Gh*Parser
  GlabClient, GlabPullRequestRepository, GlabGraphQLQueries, Glab*Parser   (ported from the main app, models renamed)
  RoutingCodeHostRepository   holds both and forwards by the project's descriptor (so stores hold one port)
```

GitHub mapping (through `gh`, verified by the implementing session with `gh api graphql` introspection before writing a query):

| Operation | GitHub |
|---|---|
| list | GraphQL `search(type: ISSUE, query: "repo:o/r is:pr state:open author:@me")` for Mine, `review-requested:@me` for To review, `assignee:@me` for Assigned, `repository.pullRequests(states:, orderBy: UPDATED_AT)` for All; fields `number title isDraft state url author{login} headRefName baseRefName mergeable mergeStateStatus reviewDecision reviews(first:100, states:[APPROVED]){nodes{author{login}}} reviewThreads(first:100){totalCount nodes{isResolved}} additions deletions changedFiles commits{totalCount} labels{nodes{name}} autoMergeRequest{enabledAt} viewerCanUpdate headRefOid createdAt updatedAt mergedAt closedAt mergedBy{login} statusCheckRollup / commits(last:1){nodes{commit{statusCheckRollup{state contexts(first:50){nodes{... on CheckRun{name conclusion status detailsUrl} ... on StatusContext{context state targetUrl}}}}}}}` ; paging with `pageInfo{hasNextPage endCursor}` |
| status(branch) | `gh pr view <branch> --json number,state,isDraft,url,mergeable,reviewDecision,statusCheckRollup,baseRefName,headRefOid` (exit 1 with "no pull requests found" means none) |
| details | GraphQL `pullRequest(number:){ body reviewThreads(first:100){nodes{id isResolved comments(first:100){nodes{id body author{login} path line originalLine url}}}} }`; failed jobs from `statusCheckRollup` contexts with `conclusion: FAILURE` |
| diffs | `gh pr diff <n>` (unified diff, parsed by the existing `GitDiffOutputParser`), file list from `gh pr view --json files` |
| approve / revoke | `gh pr review <n> --approve`; revoke = GraphQL `dismissPullRequestReview` on my latest approved review (`canRevokeApproval: true` only when such a review exists) |
| draft | `gh pr ready <n>` and `gh pr ready <n> --undo` |
| updateBranch | `gh api -X PUT repos/o/r/pulls/<n>/update-branch` (merge of base into head; GitHub has no rebase from the API, the UI says "Update branch") |
| retry / cancel checks | `gh run rerun <runID> --failed`, `gh run cancel <runID>`; run IDs from `gh run list --branch <b> --json databaseId,status,conclusion,workflowName --limit 10`; `hasRetryChecks` only when GitHub Actions runs exist |
| merge | `gh pr merge <n> --squash|--merge [--delete-branch] --match-head-commit <sha>`; the squash default comes from `repository.squashMergeAllowed` / `mergeCommitAllowed` |
| auto-merge | `gh pr merge <n> --auto --squash|--merge`; cancel `gh pr merge <n> --disable-auto` |
| create | `gh pr create --base <t> --head <s> --title … --body-file <tmp> [--draft] [--label …]`; `deleteSource` has no create-time flag on GitHub: the merge step passes `--delete-branch` |
| labels | `gh label list --json name --limit 200` |
| resolve thread | GraphQL `resolveReviewThread(input:{threadId})` |
| reply | `gh api -X POST repos/o/r/pulls/<n>/comments/<commentID>/replies -f body=…` (`@` prefix: leading space, same trick as glab) |

Everything the Pull Requests tab shows is driven by `CodeHostCapabilities`: a missing capability hides the button, it never shows an error. UI words come from the descriptor: the tab title is "Pull Requests" or "Merge Requests", the reference is `#12` or `!12`, "Open on GitHub" or "Open on GitLab".

Tests: `GhPullRequestParserTests` with recorded `gh` JSON fixtures (anonymised), `GlabPullRequestParserTests` with the existing fixtures renamed, `CodeHostDetectorTests` (ssh, https, custom host, config override), `RoutingCodeHostRepositoryTests`, and the store tests over `SpyCodeHostRepository`. Integration suite `GhIntegrationTests` (tagged, skipped by default) against a throwaway repository the user creates with `gh repo create <name> --private`.

## 7. Feature plan per area

Legend: **keep** = the main app's code moves as is (names anonymised); **port** = comes from the generic app; **generalise** = rewrite the project-bound part on config; **drop** = not in the generic app.

### 7.1 Shell, shared objects, UI

- keep: `AppWindows` (status item, panel, pinned window, request windows renamed to `DevHubPullRequestWindow`), `RootView`, `HeaderView`, `FooterView`, drag and resize, `HintCenter`, `WindowLayout`, `CommandLog` and the Output panel, `Toaster`, `ActivityLog`, `Navigator`, `ProjectSession` (search per tab), `AppActions`, `ActionRunner` (busy sequences), `RefreshTask`, `AppEvent`, every `DevHubUI` component (58 files; list in the main app's `Sources/DevHubUI/`).
- port: `SearchablePicker` (generic `UI/Components/SearchablePicker.swift`; the main app has only `BranchPicker`), `KeyValueBlock`, `InlineError`, `EmptyState` (map onto `ListState` where it exists), `SampleDataBanner` (drop), `ToastOverlay` (compare with `ToastView`, keep one).
- port: debug launch switches into `DevHubComposition/Debug/` (`DebugLaunch`, `DebugGitOps`, `DebugLaunch+Build`, `+Logs`) and a `DEVHUB_SNAPSHOT` path. They stay out of Release: wrap the reader in `#if DEBUG`.
- generalise: status item title `StatusItemTitle` shows usage percent (Claude, Copilot) and the review count; `FeatureRegistry.all` becomes `FeatureRegistry.builtIn + customTabs` (section 7.8).
- Tabs and order: Home, Git, Pull Requests, Worktrees, Simulators, Logs, Network, AI, Settings (gear, not in the bar). Custom tabs after Network, before AI? No: after all built-ins, so ⌘ numbers of built-ins never move.
- `AppSettings` (global): `launchAtLogin`, `showDockIcon`, `globalShortcut`, `showUsageStrip`, `showClaudeUsageInMenuBar`, `showCopilotUsageInMenuBar`, `showReviewCountInMenuBar`, `editor`, `terminal`, `ticketURLTemplate` (global default), `autoFetchMinutes` (global default), `scriptsFolder` (drop: the global layer is `~/.devhub/scripts`).

### 7.2 Projects and config

- port from generic: projects list, selection, detection (`ProjectDetector` of generic and `XcodeProjectDetector` of main merge: shared schemes plus `xcuserdata`, bundle ID exclusions union), "Create .devhub example", "Open .devhub folder", config problems section on Home.
- port: the whole config system (section 4 table). Detailed file plan in Appendix B.
- generalise: `Project` loses `identity: DeviceIdentityConfig?`; the effective project (config merged with detection and the run bar choice) is a Domain policy `EffectiveProjectPolicy` fed by `ProjectSession`.

### 7.3 Git

- keep: everything in the main app's Git feature (header, pills, Local in three sections with bulk delete, Remote, History with files and diffs and refs, Reflog, Changes, Stash list, commit box, switch with local changes, fetch on open, ticket chip, request line and tags).
- generalise: `git.remote` replaces the literal `origin` in `GitCommandEncoder`, `ShellGitRepository`, `RemoteBranchParser`, `GitLogQuery`, `MergedBranchPolicy`, use cases; base branch from `git.baseBranch`, else `<remote>/HEAD`, else `<remote>/main` (`BranchName.defaultBaseRef` is removed; `BranchName` keeps `local(remotePrefix:)` helpers that take the remote name); `BranchCleanupPolicy.protectedNames` and `MergeRequestTargetPolicy.preferred` take config lists; `TicketPrefix` takes the pattern and format from config; `SwitchBranchUseCase` stash message stays `DevHub: switch to <b>` (neutral); the request template path comes from the host descriptor.
- generalise: worktrees folder, include list and bootstrap from `git.worktrees.*` (generic semantics: `folder` relative to the repo, default sibling `<repo>-<branch>`; `include` paths copied when missing; `bootstrap` script run when `bootstrapMarker` exists in the main checkout and not in the worktree). `init.sh` and `.worktreeinclude` and `.claude/worktrees` disappear from code; the `claude` tag on worktree rows disappears.
- port from generic: config pills (`git.pills`) in the header action bar, `git.branchRow` actions in the row menus, `DEVHUB_GIT_OPS` debug script.
- "Copy for Slack" becomes "Copy Link with Title" (`RequestLinkText`).
- "Open in Xcode" on file rows becomes "Open in Editor" through the Settings editor (`xed` for Xcode, `code --goto` for VS Code and Cursor, `zed` for Zed, else `open`).

### 7.4 Pull Requests (section 6)

- The GitLab feature is renamed to `PullRequests` (`FeatureID.pullRequests`), models renamed (`MergeRequest*` to `PullRequest*`, `MergeDetail` to `MergeReadiness`, `PipelineStatus` to `CheckStatus`, `MergeRequestThread` to `ReviewThread`), the store split (`PullRequestsStore` under 300 lines, `PullRequestListCache`, `PullRequestActions`), list styles kept (Detailed, Calm, Compact), split layout kept, the separate window kept.
- `GhPullRequestRepository` is new; `GlabPullRequestRepository` is the port. `RoutingCodeHostRepository` picks per project.
- "Fix with Claude" becomes "Fix threads with AI" and runs `ai.reviewCommand` from config (default `claude`), with `{prompt}` replaced by the prompt file path. The prompt text says "post as replies on the pull request" (no host name).
- The review count poll (5 min) and the menu bar count stay, now per host.

### 7.5 Build & Run, Simulators, Logs

- keep: the main app's `BuildStore`, `BuildAndRunUseCase`, `PrepareBuildCheckoutUseCase`, `LaunchInstalledAppUseCase`, `ProductLocator`, `BuildOutputParser`, `XcodeContainer`, `AccessibilityXcodeAttacher`, `SimctlSimulatorRepository`, `ContainerLocator`, `SimctlMessagingRepository`, `SimulatorsStore`, `MessagingStore`, `LaunchPicker`, per-simulator run options, favourites, remove apps, erase, cached `.app` reinstall, `SimctlAppLogRepository`, `LogsStore`, `LogRedactor`.
- port from generic: launch profiles (env, args, defaults written to the container, `cleanInstall`), `kind: command` projects (`build.command`, `run.command`, the `app` directive), `simulators.statusScript` with its row line, `simulators.runBar` and `simulators.row` config actions, log streams per simulator as chips (`logs.streams` saved; the generic Logs tab has several streams at once, the main app has one: keep the generic chips UI on the main app's repository), `logs.subsystem` predicate, `logs.toolbar` actions, the Copilot and Claude executable lookup for AI.
- generalise: deep link schemes from `simulators.deepLinks`; push template title "Example"; the Simulator.app open step before launch (main has it; generic lacks it); `BuildState.scheme` default from detection.
- gaps closed on the way (from section 3.2): keychain reset on clean install, worktree creation for a branch without checkout (main has it), per-simulator options (main has it), container scan for shut-down simulators (main has it), build log viewer stays "open in Console" (P2 idea), schemes from `xcuserdata` too.
- Only iOS runtimes are listed in v1 (both apps do this); the parser keeps the platform.

### 7.6 Launch identities and the state directive (generalised Device identity)

What stays: the identity panel (ID field, New, Own, Saved with aliases, Forget), the profile picker, the "Now on this simulator" summary, the clean-install note and policy, the debug-hooks tag, reinstall without a rebuild, per-simulator desired settings, the 4 s re-read after a launch.

What changes:

| Today (main app) | Generic |
|---|---|
| one `DeviceIdentityConfig` preset matched by bundle ID | `launch.identity` and `launch.profiles` from config; no presets |
| three fixed environment variable and argument names of the owner's app | `launch.identity.variable`, `keptVariable`, `args` |
| plist suite and key `group.…` / one fixed key name, env names `qa/dev/prod` | `launch.profiles[].storage`, profile ids and titles; `production: true` for the red one |
| `SessionLogReader` + `SessionLogParser` read the app's log for device ID, user, host | the status script prints `@devhub {"state": {"identity": "…", "user": "…", "host": "…"}}`; DevHub reads the version from `Info.plist` and the stored profile from `storage` |
| `AppIdentity` | `AppStateReport` (version, storedProfile, identity, user, host, readAt) |
| `CleanInstallPolicy` compares with the session log | compares desired identity with `AppStateReport.identity`, else with `LaunchRecord.appliedIdentity` (what DevHub launched last) |
| hooks tag greps the binary for the variable | same, `hookMarker` from config |
| `IdentityPanelMapper` tints `prod` red and `dev` purple | tint from `production` and the profile index |

File-level plan in Appendix A.

### 7.7 Network monitor and mock server

- keep: `LocalMockServer`, `NWMockServerRepository`, `HTTPRequestParser`, `HTTPResponseSerializer`, `HTTPForwarder`, `MockExchangeHandler`, `MockRule`, `MockSet`, `MockMode`, `MockPatch`, `JSONPatcher`, `MockRuleMatcher`, `MockRuleFactory` (default path `/`), `MockServerPortPolicy`, `FileMockSetRepository`, `MockSetFileCoder`, `MockSetsStore`, the rule editor, `NetworkRequestRedactor`, `CurlCommandBuilder`, `JSONPrettyPrinter`, request detail view, "Mock This".
- drop: `SessionLogNetworkRepository`, `SessionLogNetworkParser`, `SessionLogEntryParser`, `SessionLogFollower`, `SessionLogTail`, `NetworkRequestMerger`, the "Debug builds only, session log" texts.
- generalise: `MockLaunchEnvironment` takes the variable name from `network.baseURLVariable`; the upstream comes from the selected launch profile's `upstream` or a free URL field in the mock bar; `production: true` refuses; `UpstreamResolver` becomes `UpstreamPolicy(profiles:)`; the app status line is built from `LaunchRecord` (base URL and profile DevHub launched with, per simulator) and `AppStateReport.host` when present: "launched through DevHub on port N", "launched elsewhere: traffic may bypass the server", "server moved to port N, relaunch".
- The Network tab lists exchanges from the server only. Empty state: "Start the server in Passthrough mode and relaunch the app from DevHub to see its requests."
- WebSocket upgrades still get 501 (documented limit).

### 7.8 Custom tabs, command palette, notifications (new for both apps)

- Custom tabs: `CustomTabStore` per tab id built from `ResolvedConfig.tabs`; sections of actions (rows with inputs) and `source` scripts (`view` directive rendered through `ScriptViewRows`); `FeatureRegistry` is rebuilt on `configChanged`; ⌘ numbers continue after the built-ins; `searchPrompt` from the tab.
- Command palette ⌘K: `PaletteStore` collects `PaletteItem`s from `FeatureRegistry` (tabs), the action catalog (every action and script), simulators (boot, make target, run on), local branches (switch, run on target, create worktree), worktrees (open), AI sessions (resume), pull requests (show), settings toggles. Reuses `SearchablePicker` in a popover from the header; Enter runs the first match.
- Notifications: `notify` directive and build finished or failed, request state changed while the panel is closed, through `UNUserNotificationCenter` (permission asked once from Settings).
- Menu bar icon state: dot while a build runs, red dot after a failure until the panel opens.

### 7.9 AI sessions and usage

- keep: Claude sessions (`ClaudeTranscriptSessionRepository`), `AnthropicUsageRepository`, the usage strip and menu bar percent.
- port: Copilot sessions and usage from generic (`CopilotEventScanner`, `WorkspaceYAMLParser`, `CopilotUsageParser`, keychain item `copilot-cli`, fallback `gh auth token`), the provider filter (Copilot, Claude, both), scope filter, day groups, "copy resume command". One `AISessionRepository` port with a `provider` on each session; two Data implementations behind `CompositeAISessionRepository`.
- Usage rows with no login are hidden; errors inline with Retry (both apps agree).

### 7.10 Settings

Sections: General (launch at login, Dock icon, global shortcut, usage strip, menu bar toggles), Tools (editor, terminal), Git (ticket URL default, fetch on open default), Projects (list, add, remove, re-detect, open `.devhub`, create example), Global config folder (`~/.devhub`, Reveal), Doctor (table: git, xcodebuild, simctl, gh, glab, copilot, claude, python3 with version or "missing" and the install command; Accessibility state with a button to System Settings; notification permission state).

## 8. Milestones

Every milestone ends with: `Scripts/build.sh` prints `layers: ok`, `anonymous: ok` and the app path; `Scripts/test.sh` passes; `Scripts/smoke.sh` prints `alive`; `CHANGELOG.md`, `docs/STATUS.md` and the ADR step log updated; a commit. (Changed 2026-10-17: the owner decided that the code is never pushed, so there is no push step; see STATUS decision 1.) Inside a milestone every finished step is a commit. Commits are conventional (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`) with a plain English body and the attribution lines of the session. Never force-push.

| # | Milestone | Done when |
|---|---|---|
| M0 | Repository: `git init` in DevHubGeneric, commit the current tree as the baseline (`chore: baseline of the generic MVP`), `gh` is installed and logged in already (version 2.102, scopes `repo`, `workflow`, `read:org`, `gist`; checked 2026-10-17), the session runs `gh repo create <name> --private --source . --push` for the app and `gh repo create <name>-playground --private` for tests; `~/.devhub/anonymity-denylist.txt` created by the user; `Scripts/check-anonymous.sh` written and wired into `build.sh`; this plan saved as `docs/adr/001-port-from-main-devhub.md` with an empty step log | the remote has the baseline; `check-anonymous.sh` passes on it |
| M1 | Package import: copy `Packages/DevHubKit`, `DevHub/DevHubApp.swift`, `Scripts/{build,test,check-layers}.sh`, `docs/ARCHITECTURE.md`, `.claude/rules/*` from the main repository into DevHubGeneric; move the old `DevHub/` sources to `DevHubGeneric/legacy/` (kept in the tree until M7 as the port source, excluded from the target through the synchronized folder exception list, then deleted); update `project.pbxproj` (Swift 6, package reference, macOS 26.4); delete Slack (feature, data, domain, docs), session log files, `DeviceIdentityConfig` presets, the default project path; rename the sample vocabulary (section 5.1 rule 2) across sources, mocks, tests and previews; rewrite `AGENTS.md`, `README.md`, `CHANGELOG.md` ([Unreleased] restarted), `docs/STATUS.md` | build, tests and anonymity check green; the panel opens with Home, Git, GitLab (still named so), Worktrees, Simulators, Logs, Network, Claude, Settings; the identity panel is hidden (no config yet) |
| M2 | Config system (Appendix B steps 1 to 5): Domain config models, `ConfigMergePolicy`, `FileConfigRepository` with watcher, the ports `ConfigRepository`, `ScriptRunning`, `ToolLocating`, `ConfigStore`, `ConfigActionsStore`, placements in Home (quick actions, scripts, problems) and in every row, the example writer, launch profiles decoded, `home.quickActions`, context variables, line protocol, `when`, inputs with pickers | a script with an input from `.devhub/scripts` runs from Home, streams to the Output panel and drives the footer and toasts; editing a JSON file reloads without restart |
| M3 | Git generalisation (section 7.3) and placements `git.pills`, `git.branchRow`, `worktrees.row`; worktree folder, include and bootstrap from config; protected branches; ticket pattern from config; the legacy worktree conventions removed | every git test green with `origin/main` fixtures; a worktree is created in `git.worktrees.folder`; `DEVHUB_GIT_OPS` headless script passes on a throwaway repository with a bare remote |
| M4 | Code host (section 6): models renamed, `CodeHostRepository`, `GhClient` + `GhPullRequestRepository`, `GlabPullRequestRepository` port, `CodeHostDetector`, `RoutingCodeHostRepository`, the Pull Requests tab, header line and branch tags, new request form, "Fix threads with AI", review badge, `pullRequests.row` placement, Doctor rows for gh and glab | on the GitHub playground: list in four scopes, details with threads, diffs, approve, draft, update branch, merge, auto-merge, create, reply, resolve; on a GitLab host: the same flows the user can reach; capabilities hide what a host lacks |
| M5 | Build & Run and Simulators merge (section 7.5), Copilot sessions and usage (7.9), Logs chips, status script with row line | Build & Run of the main checkout, a worktree and a branch without checkout on a chosen simulator with a launch profile; `kind: command` project builds through its scripts; two log streams at once; AI tab lists Copilot and Claude sessions and resumes both |
| M6 | Launch identities and Network (7.6, 7.7, Appendix A): profile `storage`, `upstream`, `production`; `launch.identity`; `state` directive; `AppStateReport`, `LaunchRecord`; mock server on `network.baseURLVariable`; app status line without a session log | on an example app with `launch.identity` set: new ID, saved ID with alias, clean install on change, hooks tag; mock server passthrough shows the requests of an app launched from DevHub; patch rule changes a field; `production` profile refuses |
| M7 | Shell completion (7.8, 7.10): custom tabs rendered, command palette, notifications, menu bar state, Settings with launch at login and Doctor, debug switches in `DevHubComposition/Debug`, `legacy/` deleted | a custom tab from `.devhub/tabs` appears with ⌘8; ⌘K finds a branch and runs "switch"; a build failure notifies while the panel is closed; `legacy/` is gone and the anonymity check still passes |
| M8 | Documentation (section 9) and polish: `docs/features/*.md`, README, SPEC refreshed, `extensions.md` complete, skills and rules synced, STATUS decisions rewritten, examples complete, app icon | every doc in section 9 exists and matches the code; `grep` for the denylist finds nothing; a clone runs with the three README commands |

Order inside M1 (so the tree is never non-anonymous in a commit): copy, delete, rename vocabulary, run `check-anonymous.sh`, build, test, commit. Work uncommitted until the check passes; the tree may be large, that is fine.

## 9. Documentation set (the user asked for detailed documentation)

Plain English everywhere (short sentences, common words, no idioms). Every file below is kept current in the same commit as the code it describes.

| File | Content | Owner milestone |
|---|---|---|
| `README.md` | what DevHub is, three commands to run, first project in two minutes (`Create .devhub example`), where the docs are | M1, final M8 |
| `AGENTS.md` (+ `CLAUDE.md` with `@AGENTS.md`) | project facts, module map, conventions, build and test commands, the rules in short, skills list | M1, every milestone |
| `docs/ARCHITECTURE.md` | the contract: modules, access, rules per layer, composition, tests, lint, naming, how-tos (from the main app, anonymised, plus the config system and the code host protocol) | M1, M2, M4 |
| `docs/SPEC.md` | the product spec, refreshed to the merged scope: every tab, the extension system, the technical playbook (section 8 of today's SPEC plus the main app's verified traps: GraphQL through `gh api`/`glab api`, mock server, attach), acceptance checklist | M8 |
| `docs/extensions.md` | normative config schema; must match the decoder; every field with type, default, effect | M2, M3, M4, M6 |
| `docs/examples/devhub/` | a complete `.devhub` folder that uses every field once (`project.json` with profiles, identity, network, host; actions; scripts with headers; a custom tab; status script with the `state` directive) | M2 to M7 |
| `docs/features/<tab>.md` | one page per tab (home, git, pull-requests, worktrees, simulators, logs, network, ai, settings, output, palette): what it shows, every action and what it runs, config fields it reads, saved preferences, limits | M8 (drafted per milestone) |
| `docs/STATUS.md` | stage, per-screen state, numbered decisions (rewritten from both apps, anonymous), next steps, known gaps | every milestone |
| `CHANGELOG.md` | Keep a Changelog, `[Unreleased]` per session | every commit |
| `docs/adr/001-port-from-main-devhub.md` | this plan with a step log (commit hash and what it did, one row per commit) | every commit |
| `docs/adr/002-config-system.md` | the config system inside the modules: ports, policies, stores, placements, the `Codable` exception, decisions | M2 |
| `docs/adr/003-code-host-protocol.md` | the GitHub and GitLab mapping as verified by introspection, capabilities, decisions | M4 |
| `docs/adr/004-launch-identities-and-network.md` | the generalised identity and mock server design, the state directive, decisions | M6 |
| `docs/testing.md` | how to run tests, spies, fixtures, integration suites, the playground repository | M1, M4 |
| `.github/skills/*/SKILL.md` (symlink `.claude/skills`) | `add-feature`, `add-use-case`, `data-layer`, `ui-components`, `testing`, `xcode-toolchain`, `panel-window`, `extensions`, `build-and-run` (debug switches), `code-host`, `update-docs` | per milestone |
| `.claude/rules/*.md` | `layers`, `domain`, `data`, `presentation`, `testing`, `anonymity` (new) | M1 |
| Hooks | `Scripts/ai/session-brief.sh`, `check-changelog.sh` for Claude and Copilot (keep the generic set) | M0 |

## 10. Verification

Automated, every commit:

1. `Scripts/build.sh` prints `layers: ok`, `anonymous: ok`, then the `.app` path; anything else is a failure.
2. `Scripts/test.sh` passes (`--skip integration` by default in the stop hook; the full run before a milestone commit).
3. `Scripts/smoke.sh` prints `alive`.
4. `Scripts/check-anonymous.sh` reads `~/.devhub/anonymity-denylist.txt` plus the built-in patterns over the whole tree, including `docs/`, `CHANGELOG.md` and the last commit message (`git log -1 --format=%B`).

Headless checks (debug switches, Debug builds only): `DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=git DEVHUB_SNAPSHOT=/tmp/git.png`, `DEVHUB_GIT_OPS`, `DEVHUB_BUILD_RUN`, `DEVHUB_RUN_ACTION`. The snapshot trap from the generic STATUS (decision 34) applies: check results on the command line too.

Live checks per milestone:

- M3: a throwaway repository with a bare remote: every write operation; a large real repository read-only.
- M4 GitHub: the playground repository has `main`, three feature branches, two open pull requests (one draft, one with a review thread and a failing GitHub Actions check from a trivial workflow), one merged. Run the integration suite `GhIntegrationTests` (tagged, needs `DEVHUB_PLAYGROUND=owner/repo`) and click through the tab. GitLab: the user's own host from their machine config; the repository never names it.
- M5: Build & Run on a shut-down and a booted simulator, cancel in the middle, Run & Attach, a remote branch with no worktree, two log streams.
- M6: an example app (the user's, through their private `~/.devhub/projects/<name>/project.json` layer) with identity and profiles; passthrough and patch.
- M7: custom tab, palette, notification with the panel closed, launch at login, Doctor.

Manual screen checks before every commit that changes a view (`Scripts/run.sh` and look), as both `AGENTS.md` files require.

## 11. Notes for the implementing session

- Read in this order: this ADR, `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/extensions.md`, the `testing` and `data-layer` skills, then the main repository's `docs/STATUS.md` decisions 2, 8 to 14, 19 to 29 (the generic truths; skip the ones that name the owner's app).
- The main repository is read-only reference material. Copy files from it, never link to it, never mention its path, hosts or names in the new repository.
- The owner's private project settings go into `~/.devhub/projects/<folder>/project.json` on this machine, never into the repository. The implementing session may write that file for the user's own project to test M6 (it is outside the repository).
- When a GitHub GraphQL field is unsure, run `gh api graphql -f query='{ __type(name: "PullRequest") { fields { name } } }'` first, as the main app did with GitLab.
- One feature per commit, pushed when the remote accepts it. A half-done feature stays unreachable from the UI.
- Ask the user only when a decision changes the config schema or removes a feature; otherwise pick the simplest option, write it into `docs/STATUS.md` decisions, and continue.

## Appendix A. Identity and Network file-level plan (milestone M6)

Paths are relative to `Packages/DevHubKit` (same layout in both repositories). Facts checked in the main repository on 2026-10-17: `Ports` has 20 fields, `UseCases` 16, `AppEvent.buildFinished(simulatorID:launchedDeviceID:)`, `MockLaunchEnvironment.variable = "DEVHUB_BASE_URL"`. The config models (`ProjectConfig` and friends) exist from M2; M6 adds the fields listed in D below if M2 did not.

### A.1 Delete

Sources: `DevHubDomain/Models/DeviceIdentityConfig.swift`, `AppIdentity.swift`, `NetworkRequestSource.swift`, `NetworkLogEvent.swift`; `DevHubDomain/Repositories/NetworkLogRepository.swift`; `DevHubData/Network/SessionLogEntry.swift`, `SessionLogEntryParser.swift`, `SessionLogFollower.swift`, `SessionLogNetworkParser.swift`, `SessionLogNetworkRepository.swift`, `SessionLogTail.swift`, `NetworkRequestAssembler.swift`; `DevHubData/Simulators/SessionLogReader.swift`, `SessionLogParser.swift`; `DevHubMocks/MockNetworkLogRepository.swift`; `DevHubTestSupport/SpyNetworkLogRepository.swift`; `DevHubPresentation/Features/Network/Models/NetworkLogState.swift`, `NetworkRequestMerger.swift`.

Tests: `DevHubDataTests/Fixtures/SessionLogFixture.swift`, `SessionLogNetworkFixture.swift`; `DevHubDataTests/Network/SessionLog*Tests.swift` (five files); `DevHubDataTests/Simulators/SessionLogParserTests.swift`, `SessionLogReaderTests.swift`; `DevHubDataTests/Mocks/MockNetworkLogRepositoryTests.swift`; `DevHubDomainTests/Models/DeviceIdentityConfigTests.swift`; `DevHubPresentationTests/Mappers/Network/NetworkRequestMergerTests.swift`.

Keep: `DevHubData/Simulators/ContainerLocator.swift` and its tests, `DevHubData/Logs/LogRedactor.swift`, all of `DevHubData/Network/MockServer/` and `MockSets/`.

### A.2 Rename

| From | To |
|---|---|
| `Domain/Models/BuildIdentity.swift` | `Domain/Models/LaunchPlan.swift` |
| `Domain/Models/SimulatorIdentitySettings.swift` | `Domain/Models/SimulatorLaunchSettings.swift` |
| `Domain/Repositories/DeviceIdentityRepository.swift` | `Domain/Repositories/AppLaunchRepository.swift` |
| `Domain/Errors/DeviceIdentityError.swift` | `Domain/Errors/AppLaunchError.swift` |
| `Domain/Policies/UpstreamResolver.swift` | `Domain/Policies/MockUpstreamPolicy.swift` |
| `Data/Simulators/SimctlDeviceIdentityRepository.swift` | `Data/Simulators/SimctlAppLaunchRepository.swift` |
| `Mocks/MockDeviceIdentityRepository.swift` | `Mocks/MockAppLaunchRepository.swift` |
| `Mocks/MockData+Identities.swift` | `Mocks/MockData+InstalledApps.swift` |
| `TestSupport/SpyDeviceIdentityRepository.swift` | `TestSupport/SpyAppLaunchRepository.swift` |
| the matching test files | same new names |

`IdentityStore`, `Features/DeviceIdentity/`, `IdentityLookup`, `IdentityPanelMapper` keep their names: an identity (an environment value that carries a device or account ID) stays a generic concept.

### A.3 New Domain types (one per file, `package init`)

- `LaunchConfig` (`profiles: [LaunchProfile]`, `identity: LaunchIdentityConfig?`), `LaunchProfile` (`id, title, env, args, defaults: [ProfileDefault], cleanInstall, storage: ProfileStorage?, upstream: String?, production: Bool`), `ProfileDefault` (`suite, key, value, type: string|bool|int`), `ProfileStorage` (`suite, key`).
- `LaunchIdentityConfig` (`variable, keptVariable?, args, idPrefix = "devhub-", cleanInstallOnChange = true, hookMarker?`; `var marker`; `func newIdentity(uuid:)`).
- `SimulatorsConfig` (`statusScript?`, `deepLinks`), `NetworkConfig` (`baseURLVariable`, `mocksFolder?`, `isMockServerEnabled`).
- `AppStateReport` (`identity, profile, host, user, version`, all optional): the parsed `state` directive.
- `SimulatorStatus` (`report?`, `keyValues: [KeyValue]`, `text?`, `failure?`): one status script run.
- `InstalledApp` (replaces `AppIdentity`): `isInstalled, version?, hasIdentityHook, keepsIdentity, storedProfileID?, report?, keyValues`; `static let notInstalled`.
- `LaunchRecord` (`Codable`): `profileID?, identity?, baseURL?, date`: what DevHub launched with, saved per simulator.
- `LaunchPlan` (replaces `BuildIdentity`): `bundleID, identityConfig?, identity?, profile?, baseURLVariable`.
- `SimulatorLaunchSettings`: `desiredIdentity, desiredProfileID, appliedIdentity, hasApplied, lastLaunch: LaunchRecord?`.
- Port `SimulatorStatusRepository`: `status(udid:bundleID:script:projectPath:) async -> SimulatorStatus`.
- Port `AppLaunchRepository`: `inspect(udid:bundleID:identity:storage:) -> InstalledApp`; `applyProfile(_:udid:bundleID:)`; `cleanInstall(udid:bundleID:fallbackAppPath:)`; `launch(udid:plan:environment:waitForDebugger:) -> Int32?`.
- `ReadInstalledAppUseCase` (ports `launcher`, `simulatorStatus`): `execute(udid:project:) -> InstalledApp`, runs the script only when `simulators.statusScript` is set.
- `MockUpstreamPolicy.upstream(for profile:) throws -> URL`: nil profile `noProfile`; `production` `productionRefused`; missing or non-http(s) `upstream` `noUpstream`.
- `CleanInstallPolicy.needsCleanInstall(app:settings:desiredIdentity:config:)`: false unless installed and `cleanInstallOnChange`; actual = `app.report?.identity ?? (settings.hasApplied ? settings.appliedIdentity : nil)`; result `actual != desiredIdentity`. The UUID heuristic is deleted.
- `MockLaunchEnvironment.variables(port:variable:)` returns `[:]` for an empty variable name.
- `MockServerError` cases: `productionRefused(profile:)`, `noUpstream(profile:)`, `noProfile`, `disabled`, `noSetChosen`, `startFailed`; messages name `network.baseURLVariable` and `launch.profiles[].upstream`.

### A.4 Change (one to three lines per file)

Domain: `Project` gets `config: ProjectConfig = .empty` instead of `identity:`; `IdentityLaunch` carries `plan: LaunchPlan`; `BuildRequest.launch: LaunchPlan`; `BuildEvent` gains `case launched(LaunchRecord)` (three `switch` sites get the case); `MockRelaunchRequest` carries `plan`; `MockServerState` gains `profileID?`; `NetworkRequest` loses `source`; `MockSetRepository` methods take `folder: URL`; `MockLaunchPreparation` uses `mockServer` only and `MockUpstreamPolicy`; `BuildAndRunUseCase` calls `applyProfile` then `launcher.launch` then yields `.launched`; `LaunchInstalledAppUseCase.execute(_:cleanInstall:) -> LaunchRecord`; `RelaunchWithMocksUseCase` returns `(state, launch)` and throws `.disabled` on an empty variable; `Ports`: remove `network`, rename `identity` to `launcher`, add `simulatorStatus` (20 fields); `UseCases`: add `readInstalledApp` (17).

Data: `SimctlAppLaunchRepository.inspect` reads `Info.plist` version, greps the binary for `marker` and `keptVariable`, reads the `storage` plist; `applyProfile` writes typed defaults (`-string|-bool|-int` when booted, typed plist values when shut down); `launch` sets `variable` and `keptVariable` (empty when no identity), appends `profile.env`, `profile.args`, `identityConfig.args`. New `StatusScriptRunner` (port of the generic runner, 5 s timeout), `AppStateDirectiveParser`, `ScriptSimulatorStatusRepository` (containers from `simctl get_app_container` with `ContainerLocator` fallback, env `DEVHUB_SIMULATOR_UDID`, `DEVHUB_BUNDLE_ID`, `DEVHUB_APP_CONTAINER`, `DEVHUB_DATA_CONTAINER`). `ShellRunner.stream` gains `environment:`. `FileMockSetRepository` takes `folder:`; `XcodeProjectDetector` drops the preset lookup; `Ports+Live` wires `launcher`, `simulatorStatus`, drops the session log repository.

Mocks and spies: `Ports+Mock`, `Ports+Spies`, `PortSpies` follow; `MockData+Projects` uses `example-app`, `com.example.app`, two profiles (`staging` with `upstream`, `production` with `production: true`), identity variable `APP_DEVICE_ID`, `network.baseURLVariable: "APP_BASE_URL"`, `simulators.deepLinks: ["example://"]`; `MockData+InstalledApps` with `identity: "devhub-3f9a1c2e"`, `profile: "staging"`, `host: "api.staging.example.com"`, `user: "qa-12"`.

Presentation: `IdentityLookup` (`launchPlan(for:)`, `needsCleanInstall(id:)`, `settings(for:)`, `storedProfileID(for:)`, `lastLaunch(for:)`, `installedApp(for:)`); `AppEvent.buildFinished(simulatorID:launch:)`, `appLaunched(simulatorID:launch:)`; `IdentityStore` keeps `apps: [Simulator.ID: InstalledApp]`, reads config from `session.selectedProject.config.launch`, stores `lastLaunch` on both events, drops `lastLaunch` when the app is gone or the project changes; `IdentityPanelMapper` tints by `production` (red) else teal, hooks texts from `variable`, summary fallback `profile?.title ?? "default"`; `BuildStore` builds `BuildRequest.launch` from `identity.launchPlan(for:)` and posts the record; `LaunchPickerMapper`, `RunBarMapper` take `config`, `profiles`, `settings`, `app`, `lastLaunch`; `NetworkStore` keeps selection, filter, pause, clear over `(frozenExchanges ?? liveExchanges).reversed()`, nothing else; `MockServerStore.relaunchRequest` builds the plan with `storedProfileID ?? desiredProfileID`; `restoreServers` re-resolves the upstream and skips production; `MockSetsStore` uses `config.network.mocksFolder ?? ~/.devhub/mocks/<stem of folder name>` (same `MockRouteName.stem` so existing sets are found); `MockServerBarMapper.appStatus(state:app:lastLaunch:)` has five branches (not installed; no launch record: "launched outside DevHub, traffic may bypass the server"; old port; `report.host` not local; profile mismatch; else green) and the hint says "as of the last launch from DevHub"; `NetworkView` has three empty states (no booted simulator; server off; waiting); `MessagingStore.schemes` from config, alert title "Example"; `SimulatorRowMapper` takes `app: InstalledApp?`; `ProjectSettingsRowMapper` tags a project whose config has `launch.identity`; `PresentationAssembly`, `+Preview`, `StoreHarness` wire `launcher` and `readInstalledApp`; `AppContainer.defaultProjects` is empty.

### A.5 Tests

Rewrite under the same names: `CleanInstallPolicyTests` (about 8 cases), `MockUpstreamPolicyTests`, `MockLaunchEnvironmentTests`, `MockLaunchPreparationTests`, `BuildAndRunUseCaseTests` (+ `profileCleanInstallForcesReinstall`, `launchedEventCarriesTheRecord`), `LaunchInstalledAppUseCaseTests`, `RelaunchWithMocksUseCaseTests` (`productionProfileIsRefused`, `emptyBaseURLVariableIsRefused`), `UseCasesTests`, `PortSpiesTests`, `PortsLiveTests`, `PortsMockTests`, `MockDataTests`, `MockAppLaunchRepositoryTests`, `XcodeProjectDetectorTests`, `IdentityStoreTests` (+ `appLaunchedStoresTheLaunchRecord`, `buildFinishedStoresTheLaunchRecord`, `refreshRunsTheStatusScriptWhenConfigured`), `MockServerStoreTests`, `NetworkStoreTests` (about 12), `BuildStoreTests`, `MockServerBarMapperTests` (five branches), `IdentityPanelMapperTests`, `RunBarMapperTests`, `LaunchPickerMapperTests`, `SimulatorRowMapperTests`, `ProjectSettingsRowMapperTests`, `MessagingStoreTests`, `NetworkToolbarMapperTests`, `NetworkRequestRowMapperTests`, `NetworkRequestDetailMapperTests`, `PresentationAssemblyTests`, `ProjectSessionTests`.

New: `LaunchIdentityConfigTests`, `ProjectConfigTests`, `AppStateDirectiveParserTests`, `StatusScriptRunnerIntegrationTests` (tagged), `ScriptSimulatorStatusRepositoryTests`, `ReadInstalledAppUseCaseTests`, `MockSimulatorStatusRepositoryTests`, `FileMockSetRepositoryTests.folderIsTakenAsGiven`.

### A.6 Order (build and tests green after each step)

1. Additive Domain: every new type of A.3, `Project.config` with a default, `ProjectConfigFixture`, mock projects with `config:`, new model tests.
2. Session log removal: the A.1 deletions, `Ports.network` gone everywhere, `NetworkRequest.source` gone, `NetworkStore`, toolbar, view and mapper guards rewritten, `NetworkStoreTests` reduced. The old identity repository returns nil for the log-based fields meanwhile.
3. New launch stack next to the old one: ports, `LaunchPlan`, `SimulatorLaunchSettings`, `MockUpstreamPolicy`, errors, `ReadInstalledAppUseCase`, `SimctlAppLaunchRepository`, `StatusScriptRunner`, parser, status repository, `ShellRunner.stream(environment:)`, mocks, spies, `Ports.launcher` and `simulatorStatus`, Domain and Data tests.
4. Switch the callers (every Presentation item of A.4, `XcodeProjectDetector`, `AppContainer`, assembly, harness, Presentation tests).
5. Delete the old stack, scrub the last sample strings, update `docs/ARCHITECTURE.md` (ports and use case counts), `docs/STATUS.md`, `CHANGELOG.md`, write `docs/adr/003-launch-identities-and-network.md`.

### A.7 Risks

1. A status script that reports no `identity` makes the clean-install rule fall back to the last applied value; a build that already carries an identity on first launch is not detected. Accepted; `cleanInstallOnChange: false` turns the rule off per project.
2. Without a session log DevHub cannot see a launch from Xcode after a launch from DevHub. The status line says "as of the last launch from DevHub"; `report.host` from the script overrides when present.
3. `BuildEvent.launched` must be handled in every `switch` (no `default:`): three places.
4. `applyProfile` typed values on a shut-down simulator: map `type` to `-bool` / `-int` for `defaults write` and to `Bool` / `Int` for `PropertyListSerialization`; one test per type.
5. The lint wants one type per file: `KeyValue` and `ProfileStorage` get their own files or become nested types.

## Appendix B. Config system graft file-level plan (milestone M2, parts of M5 and M7)

`S/` = `DevHubGeneric/legacy/` after M1 (the generic app's `DevHub/` folder today). `T/` = `Packages/DevHubKit/Sources/`. Facts that shape the plan: the lint wants one top-level type per file and no column-0 `nonisolated` in Domain, Data, Mocks; `DevHubUI.Tint` has no `yellow` and Domain cannot import DevHubUI; `ShellRunner.stream` has no `environment:` parameter; `Shared/ActionRunner.swift` in the package is the busy-title runner (name clash, so the config runner is `ConfigActionsStore`); `SlackCatalog` was the precedent for a `Codable` Domain model read from a user JSON file (record the `.devhub` exception in `ARCHITECTURE.md` section 5 instead of 30 DTOs); `SimulatorsStore` ignores its own `.simulatorsChanged`, so script refreshes use a new event.

Reconciliation with Appendix A: the status script runs through the `ScriptRunning` port (B.2) in both places. `ScriptDirectiveParser` handles the `state` directive; `LoadSimulatorStatusUseCase` returns the richer `SimulatorStatus` of A.3 (`report`, `keyValues`, `text`, `failure`); `ReadInstalledAppUseCase` (A) takes `launcher` and `scripts`. Launch profiles land end to end in M5 (B.8 step 6); M6 adds `storage`, `upstream`, `production` and the identity block.

### B.1 Module placement

| Generic file (`S/`) | Target (`T/`) and notes |
|---|---|
| `Core/Config/ProjectConfig.swift` | `DevHubDomain/Models/Config/`: `ProjectConfig`, `XcodeConfig`, `CommandConfig`, `GitConfig`, `CommitPrefixConfig`, `WorktreesConfig`, `LaunchConfig`, `LaunchProfile`, `ProfileDefault`, `LogsConfig`, `SimulatorsConfig`, `HomeConfig`, `NetworkConfig`, `PullRequestsConfig`, `HostConfig` (one file each, `package struct … Codable, Hashable, Sendable`, `package init`, `static let empty`); `Values/KeyedDecodingContainer+FlexibleString.swift` |
| `Core/Config/ActionConfig.swift` | `Models/Config/Placement.swift` (+ `pullRequestsRow`, `networkToolbar`), `RefreshTarget` (+ `pullRequests`, `network`), `ActionRun`, `ActionCondition` (+ `host`), `ActionConfig`, `InputType`, `InputOption`, `ActionInput`, `TabConfig`, `TabSection`, `TabSource` |
| `Core/Config/ConfigModels.swift` | `ConfigLayer` (no `title`), `ConfigLayerInfo` (+ `scriptsFolderExists`), `ActionOrigin`, `ResolvedAction`, `ConfigIssue`, `ResolvedConfig`, `ConfigFile`, `ScriptFile`, `ConfigLayerFiles`; `Values/ConfigPaths.swift` |
| `Core/Config/ConfigDecoding.swift` | `Policies/ConfigDecoding.swift`; `Errors/ConfigError.swift` (`invalid(String)`, `exampleExists(String)`, `emptyCommand`) |
| `Core/Config/ConfigMerge.swift` | `Policies/ConfigMergePolicy.swift` (pure) |
| `Core/Config/ProjectConfig+Helpers.swift` | `Models/Config/ProjectConfig+Lookups.swift` (`bundleID(scheme:configuration:detected:)`, `visibleSchemes`, `quickActionIDs`); `Models/Config/EffectiveProject.swift`; `Policies/EffectiveProjectPolicy.swift` (B.6) |
| `Core/Config/ExampleConfig.swift`, `ExampleScripts.swift` | `Models/Config/ExampleFile.swift`; `Policies/ExampleConfig.swift`, `+Scripts`, `+LayerFiles` (Domain: the writer in Data and the mock loader both use it); regenerated from `docs/examples/devhub/` by `Scripts/generate-example-config.sh` |
| `Core/Parsers/PlaceholderExpander.swift` | `Policies/PlaceholderExpander.swift` |
| `Core/Parsers/ScriptDirectiveParser.swift` | `Models/Config/ScriptDirective.swift` (+ `state(AppStateReport)`), `ScriptLine.swift`; `Policies/ScriptDirectiveParser.swift` |
| `Core/Parsers/ScriptHeaderParser.swift` | `Models/Config/ScriptHeaderResult.swift`; `Policies/ScriptHeaderParser.swift` |
| `Core/Parsers/SimulatorStatusParser.swift` | `Policies/SimulatorStatusParser.swift` (last `view` or `state` directive, else last plain line) |
| `Core/Models/ScriptView.swift` | `Models/Config/ScriptView.swift`, `ScriptViewRow`, `ScriptViewTag`, `ScriptViewAction` (`tint: ConfigTint?`) |
| `Core/Tint.swift` (config part) | `Models/Config/ConfigTint.swift` (`String`, `Codable`, the ten names of `extensions.md`); Presentation `Features/ConfigActions/Models/ConfigTintMapper.swift` to `DevHubUI.Tint`; add `yellow` to `DevHubUI/Tint.swift` and `Tint+Color.swift` |
| `Core/Models/ProjectKind.swift` | `Models/Config/ProjectKind.swift` (`xcode`, `command`) |
| `Core/Models/ActionContext.swift` | `Models/Config/ActionContext.swift` (+ `pullRequestNumber`, `pullRequestURL`, `profileID`, `host`), `ActionItemContext.swift` (+ `pullRequestNumber: Int?`) |
| `Core/Models/CatalogAction.swift` | `Models/Config/BuiltinAction.swift` (enum, `id`, `named(_:)`), `CatalogAction.swift` (`id`, `source`, `inputs`, `confirm`, `needsPrompt`, `isRunnable`, `origin`, `fileName`); icons, tints and titles of built-ins move to `QuickActionTileMapper` |
| `Core/Models/ActionResult.swift` | Presentation `Features/ConfigActions/Models/ConfigActionRun.swift`, `ConfigActionProgress.swift`, `PendingConfigAction.swift` |
| `Shared/ActionCatalog.swift` | `Policies/ActionCatalogPolicy.swift` (`actions(for:resolved:quickActionIDs:facts:)`, `action(id:resolved:)`) with `Models/Config/ActionConditionFacts.swift` (`isGitClean: Bool?`, `isTargetBooted`, `installedTools: Set<String>`, `kind`, `host`) |
| `Shared/ActionContextBuilder.swift` | `Policies/ActionContextPolicy.swift` (`make(_:)`, `defaultValue(for:facts:)`, `workingFolder(cwd:context:)`) with `Models/Config/ActionContextInputs.swift` |
| `Shared/ActionRunner*.swift` | `DevHubPresentation/Features/ConfigActions/ConfigActionsStore.swift`, `+Execution.swift`, `+Directives.swift` |
| `Shared/ConfigStore*.swift` | `DevHubPresentation/Shared/ConfigStore.swift` (load, watch, reload, `effective(schemes:baseBranch:)`, posts `.configChanged`) |
| `Services/Config/ConfigProvider.swift` | `DevHubDomain/Repositories/ConfigRepository.swift`; `DevHubMocks/MockConfigRepository.swift` |
| `Services/Config/LiveConfigProvider.swift` | `DevHubData/Config/FileConfigRepository.swift` (`home: URL` injected), `ConfigFolderReader.swift`, `ExampleConfigWriter.swift` |
| `Services/Config/ConfigWatcher.swift` | `DevHubData/Config/ConfigWatcher.swift` (`@unchecked Sendable`, own serial queue, `pollInterval` injected, exposed as `AsyncStream<Void>` with `onTermination` calling `stop()`) |
| `Services/Simulators/StatusScriptRunner.swift` | `DevHubData/Config/ShellScriptRunner.swift` (timeout inside, task group); `DevHubDomain/UseCases/LoadSimulatorStatusUseCase.swift` |
| `Services/Workspace/ToolLocator.swift` | `Repositories/ToolLocating.swift` (`isInstalled(_:) -> Bool`); `DevHubData/Workspace/PathToolLocator.swift`; `DevHubMocks/MockToolLocator.swift` |
| `Features/Actions/*.swift` | `Features/ConfigActions/Views/ConfigActionMenuItems.swift`, `ConfigActionResults.swift`, `ConfigActionPrompt.swift`, `ConfigActionInputField.swift`, `ConfigActionResultView.swift`, `ScriptViewRowView.swift`; models `ConfigActionItemModel` + `Mapper`, `ConfigActionInputModel` + `Mapper` |
| `Features/Home/{QuickActions*,Scripts*,ScriptRow,ScriptHeaderHint,ConfigIssuesSection,HomeStore}.swift` | `Features/Home/Views/QuickActionsSection.swift`, `QuickActionTile.swift`, `Models/QuickActionTileModel` + `Mapper` (replaces `Models/QuickAction.swift`), `Views/ConfigIssuesSection.swift` + `ConfigIssueRowModel` + `Mapper`; `Features/Scripts/Views/ScriptsSection.swift`, `ScriptRow.swift`, `ScriptHintCard.swift`, `Models/ScriptRowModel` + `Mapper`; delete `Features/Scripts/ScriptsStore.swift`, `Domain/Models/ScriptAction.swift`, `Mocks/MockData+Scripts.swift`; no `HomeStore` |
| `Features/Git/GitPillsBar.swift` | `GitHeaderModel.configActions`, `GitHeaderMapper`, `Views/GitHeader.swift` (B.3) |
| `App/AppDependencies.swift` | `Shared/PresentationAssembly.swift`, `View+Inject.swift`, `+Preview.swift`, `DevHubComposition/AppContainer.swift` |
| `UI/Components/SearchablePicker.swift`, `KeyValueBlock.swift` | `DevHubUI/SearchablePicker.swift`, `KeyValueBlock.swift`; `FolderPicker.chooseFile(...)`; `InlineConfirmation` replaces `InlineConfirm` |

### B.2 Ports, mocks, spies, wiring

```swift
package protocol ConfigRepository: Sendable {
    func load(projectPath: String) async -> ResolvedConfig
    func changes(projectPath: String) -> AsyncStream<Void>
    func createExample(projectPath: String) throws -> String
    func existingFolder(projectPath: String) -> String?
    func locateScript(_ path: String, layers: [ConfigLayerInfo], projectPath: String) -> String?
}
package protocol ScriptRunning: Sendable {
    func run(_ request: ScriptRunRequest) -> AsyncThrowingStream<ScriptEvent, any Error>
}
// ScriptRunRequest: executable, arguments, cwd, environment, timeout: Duration?
// ScriptEvent: case output(String), case exited(Int32)
package protocol ToolLocating: Sendable { func isInstalled(_ executable: String) -> Bool }
```

- `FileConfigRepository.load` runs the folder reads in `Task.detached` (a nonisolated async method runs on the caller's actor under `NonisolatedNonsendingByDefault`); `ShellScriptRunner` calls a new `ShellRunner.stream(_:_:cwd:environment:onLine:)` overload; output lines reach `CommandLog` through `LineBatcher` so script output shows in the Output panel. `WorkspaceOpening` gains `open(_ target:) async -> String?` for `run.open` and the `open` directive.
- Mocks: `MockConfigRepository.load` resolves the example layer; `MockScriptRunner` yields one `toast` directive and `.exited(0)`; `MockToolLocator` returns true. Spies: `SpyConfigRepository` (keeps the `changes` continuation so a test can `yield()`), `SpyScriptRunner` (`events`, `runError`, `calls`), `SpyToolLocator` (`installedTools`).
- Lines: `Ports` gains `config`, `scripts`, `tools`; `Ports+Live`: `FileConfigRepository(home:)`, `ShellScriptRunner(shell:)`, `PathToolLocator()`; `Ports+Mock`, `PortSpies`, `Ports+Spies` follow; `UseCases` gains `loadSimulatorStatus`, `runCommandProject`, `readInstalledApp` (A). `PresentationAssembly`: `config = ConfigStore(repository:session:events:)` right after `session`; `configActions = ConfigActionsStore(config:scripts:tools:session:settings:workspace:checkout:worktrees:build:toaster:activity:events:store:appVersion:)` after `build`; `customTabs = CustomTabStore(config:scripts:session:checkout:worktrees:build:activity:)`; the `scripts:` parameter is removed. `View+Inject`: three `.environment` lines. `StoreHarness`: the three lazy stores.

### B.3 Placements: where config actions enter the row models

A row model gets `var configActions: [ConfigActionItemModel]` (id, title, symbol, tint, hint, isRunnable, isRunning) built by `ConfigActionItemMapper.models(for: configActions.actions(for: placement), isRunning:)` in the view that builds the model today, and passed into the mapper. Views render `ConfigActionMenuItems(items:slot:item:)` and `ConfigActionResults(placement:slot:showsResults:)`.

| Placement | Model and mapper | View | Row context |
|---|---|---|---|
| `home.quickActions` | `QuickActionTileModel`, `QuickActionTileMapper.model(for:effective:settings:branch:isRunning:)` | `Home/Views/QuickActionsSection.swift`; built-ins through `AppActions.perform(_ builtin: BuiltinAction)` | none |
| `home.scripts` | `ScriptRowModel` (+ `layerTag`, `blockedHint`, `chmodCommand`, `inputCount`), `ScriptRowMapper.model(for:isRunning:lastRun:)` | `Scripts/Views/ScriptsSection.swift`, `ScriptRow.swift` | none |
| `git.pills` | `GitHeaderModel.configActions` | `Git/Views/GitHeader.swift` appends `ActionItem`s; results under the bar | `branch`, `worktreePath = checkoutPath` |
| `git.branchRow` | `LocalBranchRowModel.configActions` | `LocalBranchRow.swift` menu + results (no result area) | `branch`, `worktreePath`, `rowID = name` |
| `worktrees.row` | `WorktreeRowModel.configActions` | `WorktreeRow.swift` context menu + results | `branch`, `worktreePath = path`, `rowID = path` |
| `simulators.runBar` | `RunBarModel.configActions`, `launchProfiles` | `Build/Views/RunBar.swift` `ActionBar` + results; new `LaunchProfilePicker.swift` | `simulatorUDID`, `simulatorName` of the target |
| `simulators.row` | `SimulatorRowModel.configActions`, `statusText`, `statusIsFailure` | `SimulatorRow.swift` overflow menu + status line | `simulatorUDID`, `simulatorName`, `rowID = udid` |
| `logs.toolbar` | `LogsToolbarModel.configActions` | `Logs/Views/LogsToolbar.swift` second line | the chip's simulator |
| `pullRequests.row` | `PullRequestRowModel.configActions` | `PullRequests/Views/PullRequestMenuItems.swift` | `branch = source`, `worktreePath`, `pullRequestNumber`, `rowID` |
| `network.toolbar` | `NetworkToolbarModel.configActions` | `Network/Views/NetworkToolbar.swift` | the selected simulator |
| `tab.<id>` | `CustomTab/Models/CustomTabSectionModel`, `CustomTabRowModel`, `CustomTabMapper` | `CustomTab/Views/CustomTabView.swift`, `CustomTabSectionView.swift` | `rowID` of `view` rows |

`ConfigActionsStore.request(_:item:slot:)` builds the `ActionContext` with `ActionContextPolicy.make(ActionContextInputs(project:, effective:, checkoutPath: checkout.checkoutPath, branch: item.branch ?? checkout.currentBranch, simulator: item.simulatorUDID ?? build.target, appPath: build.lastBuiltAppPath(), configDir: origin.directory, item:, inputs:, version:))`.

### B.4 Refresh, built-ins, directives

- `AppEvent` gains `configChanged` and `refreshRequested(RefreshTarget)`; every exhaustive `switch` and the test matcher `AppEvent+Matching.swift` get the cases. `GitStore`, `WorktreesStore`, `SimulatorsStore`, `PullRequestsStore`, `NetworkStore` refresh on their target; `.scripts` calls `config.reload()`.
- `onBuild` disappears: `AppActions.perform(_ builtin:)` maps `buildRun`, `runAttach`, `openEditor`, `openFolder`, `terminal`, `copyBranch`, `repository`, `newPullRequest`, `pullRequests`. `AppActions` gains `settings`. Views call it for `.builtin` sources and `configActions.request` for config sources, so the store never holds `AppActions`.
- Directives: `open` through `WorkspaceActions.openTarget(_:title:)`; `toast`, `copy` through `Toaster`; `notify` through the notification service (M7; `activity.log` until then); `error` marks the run failed and posts `.commandFailed` (opens the Output panel); `refresh` posts `refreshRequested`; `view` replaces the result area; `progress` updates the footer; `app` is read by `RunCommandProjectUseCase`; `state` is read by the status use cases only.

### B.5 Custom tabs

- `FeatureID` becomes `enum FeatureID: Hashable { case home, git, pullRequests, worktrees, simulators, logs, network, ai, settings, custom(String) }` with `rawValue` (`tab.<id>`), `init?(rawValue:)`, `static let builtIn`.
- `FeatureRegistry.builtIn` plus `all(tabs:)`, `feature(_:tabs:)`, `tabBarFeatures(tabs:)`; `RootView`, `FeatureTabBar`, `HeaderView` (search prompt), `SettingsView` read `ConfigStore.tabs`; `RootView` falls back to Home when the selected tab vanished.
- ⌘ numbers follow the position; `TabButton` takes an optional `KeyboardShortcut` (nil above 9: `Character(String(10))` traps).
- `CustomTabStore`: per tab, section states (`view`, `isLoading`, `error`, `lastLoad`); `open(tabID:)` runs `onOpen` sources and starts interval timers; `refresh(tabID:sectionIndex:)` for `manual`; action sections resolve ids through `ActionCatalogPolicy.action(id:resolved:)`; rows filter with `session.matchesSearch`.

### B.6 Effective project and context variables

- `EffectiveProjectPolicy.resolve(config:project:detectedSchemes:detectedBaseBranch:) -> EffectiveProject`: `name`, `kind` (`command` when no scheme and no container), `schemes`, `scheme`, `configuration` (`Debug`), `baseBranch` (config, else detected, else `<remote>/main`), `bundleID` (per scheme and configuration), `remote`, `host`.
- `ConfigStore.effective(schemes:baseBranch:)` wraps it; `BuildStore` takes `ConfigStore`, filters `schemeOptions`, seeds `state.scheme` and `state.configuration` on `.configChanged` and `.projectChanged`.
- `Shared/BuildLookup.swift` (`scheme`, `configuration`, `schemes`, `target`, `isRunning`, `lastBuiltAppPath()`), conformed by `BuildStore`, injected into `ConfigActionsStore` and `CustomTabStore`, so the run bar choice reaches `DEVHUB_SCHEME` and `DEVHUB_CONFIGURATION`.
- Launch profiles (M5): `SimulatorRunOptions.profileID: String?`, `BuildRequest.profile: LaunchProfile?`; `SimulatorRepository` gains `writeDefaults(udid:bundleID:defaults:)` and `launch(…, arguments:)`; `BuildAndRunUseCase.launch` writes defaults, merges `profile.env`, appends `profile.args`, `cleanInstall = request.cleanInstall || profile.cleanInstall`.
- `kind: command`: `RunCommandProjectUseCase` (`scripts`, `simulators`) streams `build.command` then `run.command` as `BuildEvent`s and installs and launches the `app` directive path; `BuildStore.run` picks it when `effective.kind == .command`.

### B.7 Tests

Domain: `ConfigDecodingTests` (valid `project.json`, wrong-type `run`, flexible `default`), `ConfigMergePolicyTests` (layer precedence, tab replaced by id, one issue per bad file, sort by rank then title, header script without `chmod +x`), `ScriptHeaderParserTests`, `ScriptDirectiveParserTests` (every directive, invalid JSON, invalid `view`, `state`), `PlaceholderExpanderTests`, `ActionCatalogPolicyTests` (`when`, `home.quickActions` order with `builtin.*` and `script:` ids, `palette` always placed), `ActionContextPolicyTests`, `EffectiveProjectPolicyTests`, `SimulatorStatusParserTests`, `ExampleConfigTests` (the example decodes without issues), `LoadSimulatorStatusUseCaseTests`, `RunCommandProjectUseCaseTests`.
Data: `FileConfigRepositoryTests` (temporary `.devhub` tree and a `home` folder for user and global layers; `createExample` refuses an existing folder), `ConfigWatcherIntegrationTests`, `ShellScriptRunnerIntegrationTests` (`/bin/echo` with a directive, timeout with `/bin/sleep`).
Presentation: `ConfigStoreTests`, `ConfigActionsStoreTests` (prompt for inputs and confirm, remembered inputs, `refresh` posts the event, `error` directive, cancellation, `chmod +x` hint), `CustomTabStoreTests`, mapper tests (`ConfigActionItemMapper`, `QuickActionTileMapper`, `ScriptRowMapper`, `ConfigIssueRowMapper`, `LaunchProfilePickerMapper`, `CustomTabMapper`), updated row mapper tests for every placement, `FeatureRegistryTests`, `NavigatorTests`, `PresentationAssemblyTests` (store count), `AppEventsTests`; delete `ScriptsStoreTests`. Sample: `Stores/Samples/ConfigSample` (one action per placement).

### B.8 Order (build and tests green after each step)

1. Domain only: config models, values, policies, parsers, errors, `ConfigTint`, `ExampleConfig`, `yellow` in `DevHubUI.Tint`, Domain tests.
2. Ports and adapters: `ConfigRepository`, `ScriptRunning`, `ToolLocating`, `WorkspaceOpening.open`, `ShellRunner.stream(environment:)`, `FileConfigRepository`, `ConfigFolderReader`, `ConfigWatcher`, `ExampleConfigWriter`, `ShellScriptRunner`, `PathToolLocator`, mocks, spies, assembly lines, `LoadSimulatorStatusUseCase`, Data tests.
3. Presentation shared: `AppEvent` cases, `ConfigStore`, `BuildLookup`, `ConfigActionsStore` with extensions, `WorkspaceActions.openTarget`, `AppActions.perform(builtin:)`, assembly, inject, preview, harness, `AppContainer`; store tests.
4. Home and Scripts: `ConfigActions` views and mappers, `QuickActionsSection`, `ConfigIssuesSection`, `ScriptsSection`, `ScriptRow`; delete the mock scripts; Settings gets "Create .devhub example" and "Reveal .devhub"; `docs/extensions.md` moves in.
5. Placements: Git header and branch rows, worktree rows, simulator rows and run bar, logs toolbar, pull request rows, network toolbar; mapper tests.
6. Build and simulators config (M5): `BuildStore` over `ConfigStore`, launch profiles end to end, `RunCommandProjectUseCase`, simulator statuses in `SimulatorsStore.statuses` (refreshed on `.simulatorsChanged`, `.appLaunched`, `.buildFinished` for booted, favourite and target simulators), `LogsStore` process default from `logs.process` and the `logs.subsystem` predicate.
7. Custom tabs (M7): `FeatureID.custom`, dynamic registry, shortcut guard, `CustomTabStore` and views, `RootView` fallback; registry and navigator tests.
8. Docs: `ARCHITECTURE.md` (port and use case counts, the `Codable` config exception, `Features/ConfigActions`, `Features/CustomTab`), `STATUS.md`, `CHANGELOG.md`, `docs/adr/002-config-system.md`, `extensions.md`.

### B.9 Risks

1. Watcher in Data: `DispatchSource` and a timer in an `@unchecked Sendable` class with its own serial queue (allowed); `pollInterval` injected so the integration test does not wait 2 s.
2. Off-main file work: `Task.detached` inside the repository (`SimctlSimulatorRepository` precedent); never `MainActor.assumeIsolated`. The generic `lineHandler` is not ported: the store iterates the `AsyncThrowingStream` on the main actor like `BuildStore` does for builds.
3. One type per file: the three generic config files become about 35 files; strip every `nonisolated` prefix.
4. Port signature changes ripple (`SimulatorRepository.launch`, `BuildRequest`, `SimulatorRunOptions`): keep them additive and update the spies' `Call` enums and fixtures.
5. Tab shortcut trap above ⌘9: optional shortcut.
6. Stale custom tab selection after a reload or project switch: fall back to Home.
7. `PresentationAssemblyTests.previewWiresEveryStore` counts stores; update the count when stores are added or removed.

## Step log

One row per commit: the short hash and what the commit did. A commit cannot hold its own hash, so its row lands in the next commit.

| Commit | Milestone | What it did |
|---|---|---|
| `51fae01` | M0 | Baseline of the generic MVP. It was pushed once to a private GitHub repository; then the owner decided that the code is never pushed (STATUS decision 1), the remote was removed and the repository is to be deleted. The playground repository for pull request checks stays. |
| `e7106c6` | M0 | `Scripts/check-anonymous.sh` (denylist outside the repository plus built-in patterns), wired into `build.sh`; this plan saved as ADR 001 with a step log. |
| `0cb12ff` | M1 | Package import: `Packages/DevHubKit` is the app, sample vocabulary renamed, Slack and the session log removed, no default project (`NoProjectState`), Network over mock server exchanges only, debug snapshot switches, scripts stop only this build, `waitUntil` 10 s, `legacy/` holds the first app; AGENTS, README, STATUS, CHANGELOG rewritten. |
| `abe8e00` | M2 | Appendix B step 1: config models in `DevHubDomain/Models/Config`, policies (decoding, merge, header and directive parsers, placeholders, catalog, context, effective project), `ExampleConfig` generated by `Scripts/generate-example-config.sh`, `Tint.yellow`, Domain tests. |
| `f74df82` | M2 | Appendix B step 2: ports `ConfigRepository`, `ScriptRunning`, `ToolLocating`; `FileConfigRepository` with `ConfigFolderReader`, `ConfigWatcher` (injected poll interval), `ExampleConfigWriter`; `ShellScriptRunner` with timeout; `PathToolLocator`; `ShellRunner.stream(environment:)`; mocks, spies, Data tests. `LoadSimulatorStatusUseCase` moves to M5 with the status rows. |
| `3a98b84` | M2 | Appendix B step 3: `ConfigStore` (load, watch, reload, effective project), `ConfigActionsStore` (+Execution, +Directives), `BuildLookup`, events `configChanged` and `refreshRequested`, `AppActions.perform(builtin:)`, `WorkspaceActions.openTarget`, store tests. |
| `6c61847` | M2 | Appendix B step 4: Home quick actions from `home.quickActions`, Scripts from `.devhub/scripts`, config problems, inline prompt and result views, footer progress, Settings "Project config" section; `ScriptsStore` and `MockData.scripts` removed; debug switches `DEVHUB_RUN_ACTION`, `DEVHUB_REQUEST_ACTION`, `DEVHUB_SHOW_OUTPUT`. |
| `e38c6bd` | M2 | The example helper scripts get a title and `placements = palette`, so Home does not list them twice. |
| `d20e938` | M2 | Appendix B step 5: config actions in the Git header, branch, worktree and simulator rows, the run bar and the Logs toolbar; `ConfigActionBar`, `ConfigActionPromptSlot`, `request(id:)`, row models carry `configActions`; mapper and store tests. |
| `89e6680` | M2 | ADR 002, `docs/extensions.md` checked against the decoder, ARCHITECTURE, STATUS, AGENTS and the `extensions` skill for the package; booted simulators first in a `simulator` input. |
| `81460a9` | M3 | `git.worktrees` from config (folder, include, bootstrap with or without a marker), `GitSettings` and `GitSettingsPolicy`, `WorktreePathPolicy`; `init.sh`, `.worktreeinclude`, `.claude/worktrees` and the agent kind removed; fix for a re-entrant unsubscribe in `AppEvents`. |
| `8d801fb` | M3 | `git.remote` everywhere: `GitCommand` cases carry the remote, `BranchName(_:remote:)`, policies and use cases take it, `GitRepository.state(settings:)` and `webURL(remote:)`, `RemoteBranchParser`, `GitLogQuery`; hints say "the remote". |
| `77b877e` | M3 | `git.commitPrefix` pattern and format for the ticket chip, commit prefix and merge request title (`TicketSettings`, `NSRegularExpression`), `git.ticketURL` with the Settings link as fallback, `git.protectedBranches` in the cleanup. |
| `f9bcb7e` | M3 | "Open in Editor" on file rows through `EditorCommandPolicy` (`xed`, `code --goto`, `cursor --goto`, `zed`, fallback `open -a`). |
| `7be0d81` | M3 | `DEVHUB_GIT_OPS` (`PresentationAssembly+DebugGitOps`), checked on a throwaway repository with a bare remote `upstream`; the base branch is left out of the merged set. |
| `831a25b` | M3 | M3 closed in STATUS; the `build-and-run` skill rewritten for the package. |
| `37cce37` | M4 | Step 4.1: `CodeHost` (kind, host, path, web URL) and `CodeHostPolicy`; `git.host.kind` and `git.host.name`; every `MergeRequestRepository` method takes the code host; `CodeHostLookup`, `CodeHostRemote`, `CodeHostErrorMapper`; errors name the tool. |
| `909ab52` | M4 | Step 4.2: `GhClient`, `GhGraphQLQueries`, `GhPullRequestParser`, `GhCheckParser`, `GhDiffParser`, `GhCreatedPullRequestParser`, `GhMergeRequestRepository`; `CodeHostMergeRequestRepository` routes by kind; recorded and anonymised fixtures; write commands checked on the playground (auto-merge needs a paid plan for a private repository). |
| `9ee234c` | M4 | Rename to pull request names (`PullRequestSummary`, `CodeHostRepository`, `RoutingCodeHostRepository`, `PullRequestsStore`, `BranchPullRequestStore`, tab id `pullRequests`); `.gitignore` fixed so the `Build/` folders are tracked; a fresh clone builds. |
| `e364ab8` | M4 | Step 4.3: `CodeHostWords` and `\.codeHostWords` from an observable `CodeHostRemote`; every mapper takes `words:`; `canRevokeApproval` and `canSetAutoMerge` (GitHub `autoMergeAllowed`); the tab toolbar wraps on a narrow panel. |
| `c6b74d2` | M4 | `git.pullRequests` (targets, template, staleDays, defaults) and `ai.reviewCommand` in `PullRequestSettings`; the template file depends on the host kind. |
| `e31cddf` | M4 | `pullRequests.row` placement with `DEVHUB_PR_NUMBER` and `DEVHUB_PR_URL`, `when.host`, the `pullRequests` refresh target, `builtin.pullRequests`; "Fix Threads with AI"; an example action. |
| `9dc8549` | M4 | M4 closed: ADR 003, `GhIntegrationTests` (runs with `DEVHUB_PLAYGROUND`), STATUS and the testing skill. |
| `4ad41c0` | M4 | Renames from section 7.4 (`MergeReadiness`, `CheckStatus`, `ReviewThread`); `PullRequestsStore` split to 300 lines. |
| `98c7d9d` | M5 | Step 5.1: `xcode.scheme`, `schemes`, `configuration` and `container` reach the run bar and `xcodebuild` (`SchemeChoicePolicy` gets `configured`, `XcodeContainer.locate(preferred:)`). |
