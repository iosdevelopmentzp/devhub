---
name: code-host
description: "The code host layer of DevHub: one CodeHostRepository port for GitHub (gh) and GitLab (glab), the CodeHost value and CodeHostPolicy, GhClient and GlabClient, GhPullRequestRepository and GlabPullRequestRepository behind RoutingCodeHostRepository, errors, the words of each host (# or !, pull request or merge request, checks or pipeline) in CodeHostWords, capabilities and permissions that hide actions, the git.host and git.pullRequests config, and how to add a field or an operation with spies, parsers and recorded fixtures. Load before any change to the Pull Requests tab, the Git request line, branch tags, gh or glab calls, or the code host config."
---

# Code Host

A code host is the web service that keeps the repository and its review requests: GitHub or GitLab. A review request is a "pull request" on GitHub and a "merge request" on GitLab. In the code both are `PullRequest…` types. The design and the GitHub field mapping are in `docs/adr/003-code-host-protocol.md`. Paths below start at `Packages/DevHubKit/Sources/`.

## Map

| Layer | Files |
|---|---|
| Domain port | `DevHubDomain/Repositories/CodeHostRepository.swift` |
| Domain values | `DevHubDomain/Models/CodeHost/CodeHost.swift`, `CodeHostKind.swift`; `PullRequestSummary`, `PullRequestDetails`, `PullRequestList`, `PullRequestStatus`, `PullRequestPermissions`, `PullRequestQuery`, `NewPullRequest`, `PullRequestFileDiff` in `DevHubDomain/Models/` |
| Domain rules | `CodeHostPolicy`, `PullRequestTargetPolicy`, `PullRequestFilterPolicy`, `PullRequestAgePolicy`; `PullRequestError` |
| GitHub | `DevHubData/GitHub/`: `GhClient`, `GhPullRequestRepository`, `GhGraphQLQueries`, `GhPullRequestParser`, `GhCheckParser`, `GhDiffParser`, `GhCreatedPullRequestParser` |
| GitLab | `DevHubData/Git/`: `GlabClient`, `GlabPullRequestRepository`, `GlabGraphQLQueries`, `GlabGraphQLParser`, `GlabPullRequestParser`, `GlabDiffParser`, `GlabCreatedPullRequestParser` |
| Router and errors | `DevHubData/CodeHost/RoutingCodeHostRepository.swift`, `DevHubData/Git/CodeHostErrorMapper.swift` |
| CircleCI | `DevHubDomain/Repositories/CIRepository.swift`, `CIPolicy`, `CIWorkflowLink`, `CircleCIStatusMapper`, `FlakyTestPolicy`; `DevHubData/CircleCI/`; `MockCIRepository`, `SpyCIRepository`. A GitHub check that links to CircleCI carries `PipelineJob.ciWorkflowID`, and `PullRequestDetailStore` reads the workflow through the port (ADR 006, the CircleCI section of the pull-requests page) |
| Wiring | `DevHubData/Assembly/Ports+Live.swift` (`codeHost:`) |
| Mock | `DevHubMocks/MockCodeHostRepository.swift`, `MockData+PullRequests.swift` |
| Spy | `DevHubTestSupport/SpyCodeHostRepository.swift`, `CodeHost+Sample.swift` |
| Presentation | `Shared/CodeHostRemote.swift`, `CodeHostLookup.swift`, `CodeHostWords.swift`, `CodeHostWordsModifier.swift`, `EnvironmentValues+CodeHostWords.swift`; `Features/PullRequests/`; `Features/Git/BranchPullRequestStore.swift` and the request line and branch tag mappers |

## The port

`CodeHostRepository` has one method per operation: `status`, `list`, `openRequests`, `details`, `diffs`, `approve`, `unapprove`, `setDraft`, `rebase`, `retryPipeline`, `merge`, `setAutoMerge`, `cancelAutoMerge`, `cancelPipeline`, `create`, `labels`, `resolveThread`, `reply`, `comment`, `requestChanges`, `addLineComment`, `jobLog`, `retryJob`, `fileContent`, `inbox`, `markInboxDone`.

Every method takes `repository: CodeHost`. A `CodeHost` holds:

| Property | Example |
|---|---|
| `kind` | `.github` or `.gitlab` |
| `host` | `github.com`; the value for `--hostname` |
| `path` | `example/app` |
| `webURL` | `https://github.com/example/app` |
| `tool`, `name`, `requestNoun`, `referencePrefix` | `gh`, `GitHub`, `pull request`, `#` |

How a store gets the value:

1. `CodeHostRemote` (Presentation, `Shared/`) reads the web address of the remote once per project: `git.remote`, default `origin`.
2. `CodeHostPolicy.codeHost(webURL:kind:name:)` builds the `CodeHost`. `git.host.kind` and `git.host.name` from config win over the detected values.
3. Without `git.host.kind`, a host name that contains `github` is GitHub. Any other host is GitLab (STATUS decision 18).
4. A store calls `try await remote.codeHost()` through the `CodeHostLookup` protocol, then calls the port. A remote without a usable web address throws `PullRequestError.noCodeHost`.
5. `CodeHostRemote` forgets the value on `projectChanged` and `configChanged`.
6. `RepositoryWebLinks` (Domain) builds the branch, commit and new request links of the Git tab. It takes `git.host.kind` first, then `CodeHostPolicy.kind(forHost:)`, so a GitHub Enterprise host without `github` in its name gets GitHub paths.

The stores that use the port: `PullRequestsStore` (the list), `OpenPullRequestsStore` (open requests for branch tags), `PullRequestDetailStore` (details, files and every action), `NewPullRequestStore` (create, labels), `BranchPullRequestStore` (the request of the current branch for the Git request line).

## The two repositories

`RoutingCodeHostRepository` sends each call to `gitHub` or `gitLab` by `repository.kind`. `Ports.live` builds it once.

| Operation | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|
| `list`, `details` | `gh api graphql` (search API for the list, 50 per page) | `glab api graphql` (100 per page) |
| `status` of a branch | GraphQL: pull requests of the head branch and the check rollup of the branch | REST: merge requests of the source branch, then the last pipeline of the branch |
| `diffs` | REST `pulls/<n>/files` | REST `merge_requests/<n>/diffs` |
| `approve` | `gh pr review --approve` | REST `approve` |
| `unapprove` | GraphQL: find my approval, then `dismissPullRequestReview` | REST `unapprove` |
| `setDraft` | `gh pr ready` (with `--undo` for draft) | GraphQL `mergeRequestSetDraft` |
| `rebase` | REST `PUT pulls/<n>/update-branch` (a merge of the target into the branch) | REST `rebase` |
| `merge` | `gh pr merge --squash` or `--merge`, plus `--delete-branch` | REST `merge` |
| `setAutoMerge`, `cancelAutoMerge` | `gh pr merge --auto`, `--disable-auto` | GraphQL; REST `cancel_merge_when_pipeline_succeeds` |
| `retryPipeline`, `cancelPipeline` | `gh run rerun --failed`, `gh run cancel` | REST `retry`; GraphQL `pipelineCancel` |
| `create` | REST `POST pulls`, then `POST issues/<n>/labels` | REST `POST merge_requests` |
| `labels` | `gh label list --json name` | GraphQL `labels` |
| `resolveThread`, `reply` | GraphQL `resolveReviewThread`, `addPullRequestReviewThreadReply` | GraphQL `discussionToggleResolve`; REST discussion notes |
| `comment` | `gh pr comment --body` | REST `POST merge_requests/<n>/notes` |
| `requestChanges` | `gh pr review --request-changes --body` | throws; hidden by `canRequestChanges` |
| `jobLog`, `retryJob` | `GhClient.log` (`--allow-escape-sequences`) on `actions/jobs/<id>/logs`; REST `POST actions/jobs/<id>/rerun`. The job ID is the `databaseId` of an Actions `CheckRun` | REST `jobs/<id>/trace`; REST `POST jobs/<id>/retry`. The ID is the number at the end of the GraphQL job ID |
| `fileContent` | `GhClient.raw` (`-H "Accept: application/vnd.github.raw+json"`) on `repos/<owner>/<name>/contents/<path>?ref=<sha>` | REST `projects/<project>/repository/files/<path>/raw?ref=<sha>`, the path percent-encoded |
| `inbox`, `markInboxDone` | REST `notifications?per_page=50` filtered to the repository (`GhInboxParser`), then `-X GET <latest_comment_url>` for up to 10 mention or comment threads to name the actor; `-X PATCH notifications/threads/<id>` | REST `todos?state=pending&per_page=50` filtered to the project (`GlabInboxParser`); `-X POST todos/<id>/mark_as_done` |
| `addLineComment` | REST `POST pulls/<n>/comments` with `commit_id`, `path`, `line`, `side` (`lineCommentFields`) | REST `GET merge_requests/<n>` for `diff_refs` (`GlabDiffRefsParser`), then `POST …/discussions` with `position[…]` (`lineCommentFields`) |

Review and job facts in the values:

| Value | GitHub | GitLab |
|---|---|---|
| `PullRequestSummary.approvedBy`, `changesRequestedBy` | `latestReviews` with state `APPROVED` or `CHANGES_REQUESTED` | `approvedBy`; `reviewers[].mergeRequestInteraction.reviewState == REQUESTED_CHANGES` |
| `PullRequestSummary.reviewers`, `assignees` | `reviewRequests`, `assignees` | `reviewers`, `assignees` |
| `ReviewThread.createdAt`, `PullRequestNote.createdAt` | `createdAt` of the review comment | `createdAt` of the note |
| `PipelineJob.stage` | the workflow name (`checkSuite.workflowRun.workflow.name`) | the stage name |
| `PipelineJob.duration`, `allowsFailure`, `failureMessage` | `completedAt - startedAt`; never; the check run `title` when it failed and differs from the name | `duration`, `allowFailure`, `failureMessage` |

`PullRequestReviewMapper` turns the review facts into the "Approved by", "Changes requested", "Waiting for" and "Assigned to" lines of the details. `HiddenFilePolicy` (Domain) and `git.pullRequests.hiddenFiles` decide which files the details hide until "Show N hidden".

### Clients and errors

- `GhClient` and `GlabClient` run the tool through `ShellRunner`, so every call appears in the command log and the Output panel. Never start `gh` or `glab` in another way.
- `GhClient.graphql`, `rest`, `pr` and `command` add `--hostname` or `--repo`. A host other than `github.com` gets `--repo <host>/<path>`.
- `GhClient.Variable.text` becomes `-f name=value` (a string). `.typed` becomes `-F name=value` (a number or a boolean, for example `draft=true`).
- `GlabClient.graphqlArguments` sends a variable with the value `true` or `false` as `-F name=value`, so GitLab gets a boolean. Every other GraphQL variable and every REST field uses `-f`.
- The Output panel sorts `gh` and `glab` calls with one rule in `CommandKind`: a GraphQL query, a `GET` call or a `view`, `list`, `checks`, `diff` or `status` subcommand is a read; a mutation or a call that sends fields is an action. `gh auth token` is a secret. The `data-layer` skill has the details.
- A failed run becomes a `PullRequestError` through `CodeHostErrorMapper`:

| Case | Error | Text for the user |
|---|---|---|
| the tool is missing (exit 127, "command not found") | `notInstalled(tool:)` | "gh is not installed. brew install gh" |
| `401`, "token" or "auth" in the error text | `notLoggedIn(tool:host:)` | "gh is not logged in to github.com. Run gh auth login --hostname github.com" |
| anything else | `command(message)` | the trimmed error text |

### Traps

0. `gh api` refuses an answer with terminal escape codes (a job log) unless it gets `--allow-escape-sequences`. `JobLogTail` removes the codes, the timestamps and tokens, and keeps the last 200 lines.

1. `glab api -f` reads a value that starts with `@` as a file name. `GlabPullRequestRepository` adds a space before such a value (title, description, reply).
2. GitLab has no draft flag on create. A draft title gets the prefix `Draft:`.
3. On GitHub, DevHub adds the labels in a second call after create. When that call fails, the request exists without labels and the user sees an error.
4. GitHub takes no squash or delete-branch option when a request is created. The new request form shows these boxes only on GitLab (`NewPullRequestFormModel.showsMergeOptions`).
5. GitHub "update branch" merges the target into the branch. GitLab "rebase" rebases the branch. The words differ for that reason (see below).
6. The type and field names keep the GitLab words (`iid`, `pipeline`, `detailedStatus`, `retryPipeline`), and the GitLab GraphQL strings keep the GitLab names. Do not rename them (STATUS decision 19).

## Words

`CodeHostWords` (Presentation, `Shared/`) is the one place for the vocabulary (STATUS decision 21).

| Word | GitHub | GitLab | No kind yet |
|---|---|---|---|
| `requestsTitle` | Pull Requests | Merge Requests | Pull Requests |
| `request` | pull request | merge request | pull request |
| `shortRequest` | PR | MR | PR |
| `reference(12)` | `#12` | `!12` | `#12` |
| `checks`, `checksTitle` | checks, Checks | pipeline, Pipeline | checks, Checks |
| `job` | check | job | check |
| `openTitle` | Open in GitHub | Open in GitLab | Open in Browser |
| `retryChecksTitle` | Re-run Failed Checks | Retry Pipeline | Re-run Failed Checks |
| `updateBranchTitle(target:)` | Update Branch from … | Rebase onto … | Update Branch from … |
| `tool` | `gh` | `glab` | gh or glab |
| `pageSize` ("Load N more") | 50 | 100 | 50 |

Rules:

- A mapper takes `words: CodeHostWords` as an argument. A view or a row reads `@Environment(\.codeHostWords)`.
- `CodeHostWordsModifier` sets the environment value from `CodeHostRemote`. Before the first read of the remote the kind is nil and the words are neutral.
- Never write "merge request", "pull request", `#` or `!` as a literal in a mapper or a view. Add a property to `CodeHostWords` and a test to `CodeHostWordsTests`.

## Capabilities

An action that the host or the repository does not allow is hidden, never shown with an error (STATUS decision 22). The facts come with each `PullRequestSummary` in `permissions: PullRequestPermissions`:

| Permission | GitHub | GitLab |
|---|---|---|
| `canMerge` | `viewerPermission` is `ADMIN`, `MAINTAIN` or `WRITE` | `userPermissions.canMerge` |
| `canApprove` | the viewer is not the author and has any permission | `userPermissions.canApprove` |
| `canRevokeApproval` | write access | always |
| `canSetAutoMerge` | write access and `autoMergeAllowed` of the repository | `canMerge` |
| `canRequestChanges` | the viewer is not the author and has any permission | never |

Other repository facts: `squashOnMerge` (GitHub `viewerDefaultMergeMethod` is `SQUASH`) and `removesSourceBranch` (GitHub `deleteBranchOnMerge`) give the defaults of the merge form.

`PullRequestActionMapper` reads the permissions and decides which actions to show.

## Config

| Key | Effect |
|---|---|
| `git.host.kind` | `github` or `gitlab`; set it for GitHub Enterprise on a host without `github` in the name |
| `git.host.name` | the value for `--hostname` |
| `git.pullRequests.targets`, `template`, `staleDays`, `defaults.*` | the new request form and the `stale` tag (`PullRequestSettings`) |
| `git.pullRequests.hiddenFiles` | glob patterns of the files hidden from the details file list (`PullRequestSettings.hiddenFiles`, `HiddenFilePolicy`); the default hides tests, Xcode project files and lock files |
| `ai.reviewCommand` | "Fix threads with AI" |
| `when.host` | shows a config action only for one kind (`ActionCondition.host`, `ActionConditionFacts.hostKind`) |
| the `pullRequests.row` placement | config actions in the row menu, with `DEVHUB_PR_NUMBER` and `DEVHUB_PR_URL` |

The schema is in `docs/extensions.md`. A new key follows the `extensions` skill.

## Add a field

Example: show a new fact of a request in a row.

1. **Domain.** Add the property to `PullRequestSummary` (or `PullRequestDetails`) with a default in the `package init`, so the other callers still build.
2. **GitHub.** Add the GraphQL field to `GhGraphQLQueries` (`fields`, or `repositoryFields` for a repository fact). Add it to the private DTO in `GhPullRequestParser` as an optional. Map it in `summary(_:)`.
3. **GitLab.** Add the field to `GlabGraphQLQueries.fields` and to the DTO in `GlabGraphQLParser`. When the value comes from REST (`status`), change `GlabPullRequestParser`.
4. **Check the field on a real host first.** For GitHub run `gh api graphql -f query='…'` against the private test repository (`docs/testing.md` section 11). A field that the host does not send stays nil; the parser must not fail.
5. **Fixtures.** Add the field to the recorded answers: `GhFixture` (`DevHubDataTests/Fixtures/`), `GlabGraphQLFixture` or `GlabFixture`. Use only the sample vocabulary: `github.com/example/app`, `ABC-123`, `alex`, `sam`.
6. **Parser tests.** Check the new value in `GhPullRequestParserTests` and `GlabGraphQLParserTests`, and the nil case.
7. **Mock.** Set the field in `MockData+PullRequests.swift`, so previews show it.
8. **Presentation.** Map the field in the row or details mapper. Take every host word from `CodeHostWords`. Add a mapper test per state.
9. Run `Scripts/test.sh` and `Scripts/build.sh`.

## Add an operation

1. Add the method to `CodeHostRepository`.
2. Implement it in `GhPullRequestRepository` and `GlabPullRequestRepository`. When one host cannot do it, hide the action with a permission (above). Do not throw a "not supported" error to the user.
3. Add the method to `RoutingCodeHostRepository`.
4. Add a `Call` case, a scripted result or error, and the method to `SpyCodeHostRepository`.
5. Add the method to `MockCodeHostRepository`.
6. Call it from the store that owns the action, after `try await remote.codeHost()`. Log the result with `ActivityLog`: a failure gets `outcome: .failure`.
7. Tests:
   - pure argument builders as `static func` on the repository (`mergeArguments`, `createFields`, `listVariables`, `autoMergeVariables`), checked in `GhPullRequestRepositoryTests` and `GlabPullRequestRepositoryTests`;
   - `RoutingCodeHostRepositoryTests` for the routing;
   - a store test over `StoreHarness` with `harness.spies.codeHost`: the exact calls, the state before and after, the error path.

## Tests

| What | Where | How |
|---|---|---|
| parsers | `DevHubDataTests/GitHub/`, `DevHubDataTests/Git/` | recorded, anonymised JSON in `GhFixture`, `GlabFixture`, `GlabGraphQLFixture`; check every field, an empty answer and a broken answer |
| query strings and arguments | `GhGraphQLQueriesTests`, `GlabGraphQLQueriesTests`, `*RepositoryTests` | static builders; no process runs |
| clients and errors | `GhClientTests`, `GlabClientTests`, `CodeHostErrorMapperTests` | arguments and error mapping |
| host choice | `CodeHostPolicyTests`, `CodeHostRemoteTests` | host names, config overrides |
| words | `CodeHostWordsTests`, `PullRequestGitHubWordsTests` | every word for both kinds and for nil |
| stores | `DevHubPresentationTests/Stores/PullRequests/`, `Stores/Git/BranchPullRequestStoreTests` | `StoreHarness`, `spies.codeHost`, `CodeHost.gitHubSample` and `CodeHost.gitLabSample` |
| a real host | `GhIntegrationTests` | `DEVHUB_PLAYGROUND=<owner>/<repo> Scripts/test.sh --filter GhIntegrationTests`; read only; skipped without the variable |

A spy example:

```swift
let (ports, spies) = Ports.spies()
spies.codeHost.listResult = .success(PullRequestList(username: "alex", requests: [PullRequestSummaryFixture.open], totalCount: 1))
```

Never write the name of the test account or the test repository in a test, a fixture or a doc. The anonymity check reads every file.

## Not checked on a live host

- Auto-merge on GitHub: a private repository on a free plan has no auto-merge, so the action stays hidden there.
- The GitLab flows after the M4 rename: they need a GitLab host of the owner.
