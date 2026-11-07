# ADR 015. CircleCI depth: live state, job details, flows outside a request, diagnostics

Date: 2026-11-07. Status: in progress (see the step log). The CLI reference of 2026-11-07 and the OpenAPI document of the CircleCI API v2 were read for this page; no live project was available on this Mac (`circleci setting list` answers `token_set: false`).

This page is the brief for the implementation. It holds the research results, the design and the plan. ADR 006 holds the first version of the CircleCI integration; this page changes and extends it.

## Context

After ADR 006 the CircleCI jobs of a pull request show in the details with their state, the failed tests, the flaky tags, the log, Re-run, Cancel, Approve, a history of earlier runs and an auto re-run. The review of 2026-11-07 found these gaps:

1. The details read a workflow once. A workflow that runs is not read again until the user reloads the request.
2. A CircleCI job row has no duration, no failed step, no reason line and no link. `PipelineJobRowMapper` sets `failureText` and `durationText` to nil for every CircleCI job.
3. The log is the last 200 lines of all steps joined. The error of an `xcodebuild` step is often above that.
4. CI is invisible without a pull request: the runs of the base branch, a scheduled workflow, a branch that has no request yet. `CIRepository.branchRuns` exists in Data, Mocks and TestSupport, but no store calls it.
5. A job that waits for approval shows only in the open details. There is no tag in the list, no line on Home, no notification. The workflow waits in silence.
6. The only CI notification is "checks turned to failed". There is no "passed", no "waits for approval", no "the base branch failed".
7. The auto re-run runs a compile error again up to 20 times. The flaky list is read but takes no part in the decision. A re-run on a macOS resource class spends credits.
8. When something goes wrong on the owner's other Mac, there is no way to hand the facts to a session on this Mac without the project names.

## Findings (CLI reference and API v2, 2026-11-07)

### Tool and quotas

- The CLI is free and open source (MIT). It calls the CircleCI API with the user's token. The API has rate limits whose numbers are not published; a response carries `X-RateLimit-Limit-<Second|Minute|Hour|Day>`, `X-RateLimit-Remaining` and `X-RateLimit-Reset`, a throttled request answers 429 with `Retry-After`. The developer guide names frequent polling as a cause of throttling. DevHub's reads stay rare: one read per 30 seconds for an active workflow while its details are open, one per minute per auto re-run plan, one per 5 minutes per own open request, one per 90 seconds for the branch line.
- Credits are spent by jobs, not by API calls. A re-run spends the credits of the jobs it runs again. The Free plan has 30,000 credits per month, 5 users, no card, Docker, Linux, Windows, Arm and macOS (`m4pro.medium`, one at a time); Linux Docker medium costs 10 credits per minute.
- Test Insights, and with it the flaky list, is "not currently supported for GitLab or GitHub App projects" (docs of 2026). A project connected through the GitHub App gets no flaky tags.

### Environment variables of the CLI

`CIRCLE_TOKEN` (wins over the stored token), `CIRCLE_HOST`, `CIRCLE_NO_INTERACTIVE` (no prompts), `CIRCLE_NO_UPDATE_CHECK`, `CIRCLE_SPINNER_DISABLED`, `NO_COLOR`, `CIRCLE_NO_PAGER`, and for telemetry `CIRCLE_NO_TELEMETRY`, `NO_ANALYTICS` or `DO_NOT_TRACK` (any value). `CI` turns off prompts, the spinner and the update notice at once, but other tools read `CI` too, so DevHub does not set it. The config file is `~/.config/circleci/config.yml`; the token lives in the system keyring (`auth login`), or in that file with `--insecure-storage`.

### Commands and fields used by this page

| Command | JSON fields |
|---|---|
| `circleci workflow get <uuid> --json` | `id, name, phase, outcome, current_outcome, run_id, created_at, ended_at, jobs[].id/name/phase/outcome/current_outcome/type` (as in ADR 006; seen live) |
| `circleci api api/v2/workflow/<uuid>` | the `workflow` schema of API v2: `id, name, status, created_at, stopped_at (nullable), pipeline_id, pipeline_number, project_slug, started_by, tag`. `status` is one of `success, running, not_run, failed, error, failing, on_hold, canceled, unauthorized` |
| `circleci api api/v2/workflow/<uuid>/job` | `items[]` with `id, name, job_number, started_at, stopped_at (nullable), status, type (build, approval), project_slug, approval_request_id, approved_by, dependencies, requires`; `next_page_token`. `status` is one of `success, running, not_run, failed, retried, queued, not_running, infrastructure_fail, timedout, on_hold, terminated-unknown, blocked, canceled, unauthorized` |
| `circleci job get <job-id> --json` | `id, name, type, phase, outcome, started_at, stopped_at, project_id, pipeline_id, workflow_id, executions[].index, executions[].steps[].name/type/num/phase/outcome/exit_code/command/started_at/stopped_at` (from the source of the CLI: the steps carry timestamps, no duration field; DevHub computes the duration) |
| `circleci job output list <job-id> --json` | `id, name, execution, steps[].num/name/type/phase/outcome/started_at/stopped_at/exit_code/command/output`; `--tail` changes the text view only |
| `circleci job output get <job-id> --step-num <n> --strip-ansi` | raw stdout then stderr of one step; `--condensed` is an experimental server-side filter |
| `circleci job artifact <job-id> --json` | `path, url, execution`; `-o <dir>` downloads the artifacts of the job into that folder |
| `circleci run list --branch <b> --limit <n> --json` | `id, phase, outcome, current_outcome, branch, tag, revision, repository_url, commit.subject/url/author_name/author_login, created_at, warnings[]`. `--project` is the only project flag |
| `circleci workflow list <run-id> --json` | `id, name, phase, outcome, current_outcome` of the workflows of a run |
| `circleci run get [<run-id>] --json` | the run with `workflows[].id/name/phase/outcome/current_outcome/duration` and `workflows[].jobs[]`; `--failure-report` prints a condensed text of every failed step |
| `circleci api <path>` | prints the raw body; paths are relative to `/api/v3` unless they start with `api`; exit code 4 on 4xx and 5xx |
| `circleci run approve <run-id> --job <name-or-uuid> --force --json` | `run_id, workflow_id, workflow_name, job_id, job_name` |
| `circleci workflow rerun <uuid> [--from-failed] --json` | `workflow_id, rerun_from, from_failed` |
| `circleci workflow cancel <uuid> --force` | no JSON |
| `circleci testresult list <job-id> --json` | JSONL `classname, name, result, run_time, message`; failures only without `--all` |
| `circleci api api/v2/insights/<slug>/flaky-tests` | `flaky-tests[]` with `classname, test-name, job-name, workflow-name, times-flaked, time-wasted, file, source, pipeline-number, job-number, workflow-id, workflow-created-at`; `total-flaky-tests` |

Not used: `circleci run trigger` (a run with `--parameter k=v`; no screen for it yet), `circleci preflight` (runs the working tree through CI on a `cci/preflight/` branch), `circleci my runs`, the Insights workflow metrics (`insights/<slug>/workflows`: success rate, p95 duration, credits), `circleci run watch` (blocks for up to 30 minutes; a poll of `workflow get` is lighter and lands in the command log).

### The job link

Neither `workflow get` nor `job get` gives a web link. The link of a job is `<base>/pipelines/<vcs>/<org>/<repo>/<pipeline number>/workflows/<workflow uuid>/jobs/<job number>`, where `<base>` is the scheme and host of the check link GitHub gave (else `app.circleci.com` over https), the slug `gh/<org>/<repo>` becomes `github/<org>/<repo>`, `bb/` becomes `bitbucket/`, and `circleci/<org id>/<project id>` stays. `pipeline_number` and `project_slug` come from `api/v2/workflow/<uuid>`, `job_number` from `api/v2/workflow/<uuid>/job`.

## Decisions

1. **Live workflow.** `PullRequestDetailStore` reads an active workflow (running, pending or on hold) again every 30 seconds (`ciPollInterval`) while the details of its request are loaded. When the state turns final, the store reads the failed tests, remembers the run in the history and posts `pullRequestChecksChanged`, which reloads the request. The poll stops when the details are cleared or the project changes. After a 429 the next wait doubles once.
2. **Job details through API v2.** `CIRepository` gets `workflowDetails(id:project:) -> CIWorkflowDetails` (two commands: `api/v2/workflow/<uuid>` and `api/v2/workflow/<uuid>/job`): `pipelineNumber`, `projectSlug`, `createdAt`, `stoppedAt`, and per job `number`, `startedAt`, `stoppedAt`, `approvalRequestID`. The store reads it once per workflow after `workflow get`; a failure is logged and the rows show without durations and links. `CIJobLink` (Domain) builds the job link from the base of the check link, the slug, the pipeline number and the job number. The row shows the duration (`DurationFormat`) from `startedAt` and `stoppedAt`, a running job counts from `startedAt`.
3. **The failed step.** `CIRepository` gets `jobSteps(jobID:project:) -> [CIJobStep]` (`circleci job get`, the steps of the last execution: name, status from phase and outcome, duration from the timestamps, exit code). The store reads the steps of the failed jobs (at most 5 per workflow, like the failed tests). The row's "reason" line says `Run tests failed (exit 65)`; the chevron opens the step list with a state icon and a duration per step, then the failed tests.
4. **The log by step.** `jobLog` stays a String. `CIJobLogPolicy` (Domain) orders the steps: failed steps first with their last 200 lines each, then the other steps with their last 20 lines each. Each step keeps its `== <name> (exit <code>)` header. The log button hint says so.
5. **Artifacts.** `CIRepository` gets `artifacts(jobID:project:) -> [CIArtifact]` (path, url) and `downloadArtifacts(jobID:project:) -> String` (`circleci job artifact <id> -o <folder>`, the folder is `~/Downloads/DevHub Artifacts/<job name> <job number>` and is returned). A finished job that is not an approval has a paperclip button: the first click reads the list and opens it under the job, one row per file with "Open in Browser", and "Download All" at the end that runs the download and then offers "Show in Finder".
6. **Approval outward.** A new `CIWatchStore` (Presentation) polls every minute (3 seconds until the open requests are loaded) and again on `pullRequestsChanged` and `pullRequestChecksChanged`: for every own open request whose checks are active or on hold (`CIWatchPolicy.watchedRequests`), it reads the details and the workflows, and keeps `onHold[iid]`: the approval jobs on hold (`CIWatchPolicy.jobsOnHold`). It notifies once per job (`requestApprovals`, saved per project under `gitlab.ciNotified.<project>`, forgotten when the request leaves the open list). The row of such a request gets an `on hold · <job>` tag; the Today card gets a line "approve-release of #12 waits for your approval" that opens the request, where the Approve button is. The open requests come through `OpenRequestsLookup`. A CI action in the details posts `pullRequestsChanged` after its reload, so the tag follows an approval at once.
7. **Notifications.** `NotificationKind` gets `requestChecksPassed` (the checks of an own or watched request turned from running to passed; `OwnRequestChangePolicy` adds `.checksPassed`), `requestApprovals` (decision 6) and `baseBranchChecks` (decision 9). The Settings list grows by itself (`NotificationKind.allCases`).
8. **Auto re-run with a mode.** `CIAutoRerunPlan` gets `onlyFlaky: Bool` (default on; an old saved plan without the field reads as on). `CIFailurePolicy` (Domain) classifies a failed workflow from its failed tests and the flaky list: `allFlaky` (every failed job has failed tests and every failed test is flaky), `realTests` (a failed test that is not flaky), `noTests` (a failed job without failed tests: a build or a tool error). With `onlyFlaky` the plan runs the jobs again only for `allFlaky`; otherwise it stops with a notification that names the reason ("unit-tests failed on 2 tests that are not flaky", "build failed without test results"). The menu of the Auto re-run button keeps the counts and gets a check item "Only flaky failures", saved per project as `gitlab.autoRerunOnlyFlaky.<project>` and copied into each new plan. The store reads the flaky list once and again after 10 minutes; a list that cannot be read counts as empty and is logged once. A plan that stops keeps the failed run in the history.
9. **CI outside a request.** `CIBranchRunsStore` (Presentation, Features/Git) reads `run list --branch <b> --limit 1` and `workflow list <run>` for a branch, 90 seconds stale like the request line, again after `pullRequestsChanged`. The Git header gets a CI line under the request line: the latest run of the current branch with one tag per workflow (state), Re-run Failed and Cancel per workflow through the operation log (origin `.git`), a refresh button, the subject and the age of the run, and "Open in CircleCI" when the slug has the `gh/` or `bb/` form (`<base>/pipelines/<vcs>/<org>/<repo>?branch=<branch>`); the base comes from the pipeline link of the request on the branch, because no literal CircleCI host may stand in the code (`Scripts/check-anonymous.sh`). The same store reads the base branch (`git.baseBranch`, default from the remote HEAD) every 5 minutes while DevHub runs; a run that turns failed (a new failed run, or the known run turning failed; not the first read) logs a line and notifies `baseBranchChecks` with the target `git`; the Today card shows "CI of dev failed: build-and-test" while it is failed. A tool that is not installed or not logged in stops the base watch until the project changes. No separate CI tab: the jobs of a branch run live in the request details, one click away through the request tag. A tab with a trigger form, Insights and the flaky top list is a later ADR when the need shows.
10. **Diagnostics.** "Copy CI Diagnostics" and "Save CI Diagnostics…" in the stethoscope menu of the checks header (and "CI Diagnostics…" in Settings → Doctor) build a text (`CIDiagnosticsBuilder`, `CIDiagnosticsStore`): the DevHub build, the tool state, the provider and the `ci` config, the request and its workflows as DevHub parsed them, the last 40 `circleci` commands from the command log with cwd, exit code, duration and output (the raw JSON answers), and the CI failures from Recent. `CIRedactionPolicy` (Domain) replaces the organisation, the repository, the slug, the host, the branch names, the logins and the home folder with placeholders (`<org>`, `<repo>`, `<branch-1>`, `<user-1>`, `~`), then every word of `~/.devhub/anonymity-denylist.txt` (the file of `Scripts/check-anonymous.sh`: one word per line, `re:` for a regular expression, `#` for a comment) with `<redacted>`. `RedactionWordsRepository` (Domain port, Data reads the file) gives the words. The text goes to a save panel and to the pasteboard. The test names and the messages come from the project; the user reads the file before sharing it.
11. **Tool environment.** `CircleCIClient` runs every command with `CIRCLE_NO_INTERACTIVE=1`, `CIRCLE_NO_UPDATE_CHECK=1`, `CIRCLE_SPINNER_DISABLED=1` and `NO_COLOR=1` on top of `TelemetryOptOutPolicy.environment` (which already has `CIRCLE_NO_TELEMETRY`). A message with `429` or `rate limit` maps to `CIError.rateLimited`.
12. **Command log.** `CommandKind` reads `job get`, `job artifact` without `-o`, and `api` with `GET`; `job artifact -o` is an action.
13. **Status words of API v2.** `CircleCIStatusMapper` already knows every value of the two enums above (`retried` and `blocked` read as pending, `infrastructure_fail`, `timedout` and `unauthorized` as failed, `terminated-unknown` as canceled, `not_running` as skipped).

## The test project

The owner provides a test CircleCI account later; until then every step is checked by tests and headless snapshots over the mock ports (`DEVHUB_PORTS=mock`). The owner's playground repository on GitHub can carry a CircleCI project on the Free plan: connect it through the OAuth integration (not the GitHub App, so that Test Insights and the flaky list work), then commit `docs/examples/circleci/config.yml` of this repository as `.circleci/config.yml` there. The config runs on `cimg/base` (Linux Docker, 10 credits per minute): `build` passes and stores an artifact, `unit-tests` writes a JUnit file with one test that fails on odd minutes (so a re-run passes and Insights marks it flaky), `approve-release` waits for an approval, `deploy` runs after it. The pipeline parameter `fail-unit-tests` (`always`, `never`, `sometimes`) sets the behaviour of the test job for a trigger from the web app or `circleci run trigger --parameter fail-unit-tests=always`.

## Plan

Every step: `Scripts/build.sh` prints `layers: ok`, `anonymous: ok`, `dependencies: ok` and the app path; `Scripts/test.sh` passes; `Scripts/smoke.sh` prints `alive`; one commit per step; the step log row of a commit lands in the next commit.

1. **This page** and the example config.
2. **Domain.** `CIWorkflowDetails`, `CIJobDetails`, `CIJobStep`, `CIArtifact`, `CIJobLogStep`; `CIJobLink`, `CIJobLogPolicy`, `CIFailurePolicy`, `CIRedactionPolicy`; `CIAutoRerunPolicy` with the mode, `CIAutoRerunPlan.onlyFlaky`; `OwnRequestChange.checksPassed`; `NotificationKind` cases; `CIError.rateLimited`; the `CommandKind` rules; the port methods with `SpyCIRepository`, `MockCIRepository` and `MockData`. Tests for each policy.
3. **Data.** The client arguments and the environment, `CircleCIWorkflowDetailsParser`, `CircleCIJobStepsParser`, `CircleCIArtifactParser`, the log by step, the repository methods, the downloads folder, `FileRedactionWordsRepository`. Fixtures from the schemas above, parser and client tests.
4. **Details.** The live poll, the job details, the reason line and the step list, the log hint, the artifacts rows. Store, mapper and model tests; a headless snapshot.
5. **Watch.** `CIWatchStore`, the `on hold` tag, the Today lines, the three notification kinds and their texts. Store and mapper tests.
6. **Auto re-run.** The mode, the menu, the reasons. Policy and store tests.
7. **Branch runs.** `CIBranchRunsStore`, the CI line in the Git header, the base branch poll and its Today line. Store, mapper tests; a snapshot.
8. **Diagnostics.** The builder, the redaction, the menu items, the save panel. Policy and builder tests.
9. **Docs pass** (`update-docs` skill): `CHANGELOG.md`, `docs/STATUS.md`, `docs/features/pull-requests.md`, `git.md`, `home.md`, `notifications.md`, `settings.md`, `docs/DEPENDENCIES.md`, the `code-host`, `data-layer` and `build-and-run` skills, this page.

## Verification on a live project

```sh
circleci auth login
circleci setting list --json
cd <checkout> && circleci run list --branch main --limit 3 --json
circleci api api/v2/workflow/<uuid>
circleci api api/v2/workflow/<uuid>/job
circleci job get <job-id> --json
circleci job artifact <job-id> --json
```

Then in DevHub: open a request with CircleCI checks while a workflow runs and watch the rows change without a reload; read a reason line, a step list and a log; download an artifact; approve an on-hold job from the Today line; watch a notification for a passed check and for an on-hold job; read the CI line in the Git tab on a branch without a request; save the diagnostics and read the file for project names. Every command must appear in the Output panel.

## Open questions

- The exact body of `circleci api` on a 4xx: the exit code is 4, the message format is not documented. `CircleCIClient.error` reads `429` and `rate limit` from the text.
- Whether `job artifact -o <dir>` keeps the artifact paths as folders inside `<dir>`. The Finder button opens `<dir>` either way.
- Whether `run approve --job <name>` accepts the job name of `workflow get` for a workflow with two approval jobs of the same name in different workflows. The run id narrows it.
- The flaky list of a GitHub App project is empty (Insights is not supported there). The `only flaky` mode then stops every plan after the first failure with "not flaky"; the user turns the mode off for such a project.

## Step log

| Commit | Step |
|---|---|
| `28917f2` | 1. This page and `docs/examples/circleci/config.yml`. |
| `3481e8b` | 2. Domain models, values and policies, the port methods, spies, mocks; the Data client environment, parsers, repository methods, `FileRedactionWordsRepository`; the Doctor shows the newer version. |
| `0f19b6e` | 4. The live poll of a workflow, job durations and links, the failed step and the step list, the log by step, the artifacts rows. |
| `d1cc838` | 5. `CIWatchStore`, `CIWatchPolicy`, `OpenRequestsLookup`, the "on hold" tag, the Today line, the notification; `CIPolicy.workflowIDs`. |
| `940cc90` | 6. The "only flaky failures" mode: `CIFailurePolicy` in `CIAutoRerunStore`, the check item, the per-project preference, the flaky list cache. |
| `c8cb679` | 7. `CIBranchRunsStore`, `CIBranchLine` in the Git header, the base branch watch, the Today line, the activity target `git`. |
| `503e5f8` | 8. `CIDiagnosticsStore`, `CIDiagnosticsBuilder`, `CIDiagnosticsSubjectsMapper`, the menus, `ISOTimestamp`. |
| `49621d5` | 9. Docs pass: changelog, status, the feature pages, the dependency inventory, the skills, this page. |
