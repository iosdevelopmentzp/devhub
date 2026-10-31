# ADR 006. CircleCI status and actions through the `circleci` CLI

Date: 2026-10-31. Status: in progress. The research is done; the implementation runs step by step (see the step log). The live verification is still open: the Mac has no CircleCI login.

This page is the brief for the implementation. It holds the research results, the design and the plan. The next session reads it first, then the files it names, then starts at step 1 of the plan.

## Context

Some projects keep the repository on GitHub and run CI on CircleCI, not on GitHub Actions. DevHub reads the checks of a pull request from GitHub (`gh api graphql`, `statusCheckRollup`). A CircleCI check arrives there as an external status: a name, a state and a link. `GhCheckParser.jobs` gives such a check no `id` (there is no `checkSuite.workflowRun`), so the Pull Requests tab shows only the link. There is no log, no retry, no cancel and no approve for a CircleCI job inside DevHub.

The rule of the code host layer (ADR 003) applies here too: DevHub does not call a web API itself. It runs the command line tool of the service through `ShellRunner`. The tool keeps the login token. Every call lands in the command log and the Output panel.

## Findings

### The tool

- `circleci` is the official CLI (`github.com/CircleCI-Public/circleci-cli`). The 1.x line is a rewrite from 2026, made for scripts and agents: every data command has `--json`, `--jq` and a flag list. Version 1.13.0 is from 2026-10-30; the project released five versions in the last ten days of October, so flags can still move. Install: `brew install circleci`. It is not installed on the development Mac yet.
- The old 0.1.x CLI has none of the commands below. The Doctor row must show the version and warn when it is below 1.
- Reference: `cli.circleci.com/reference/` (one long page, all commands and flags).

### Authentication

- `circleci auth login` opens the browser (OAuth with PKCE, a loopback server on `127.0.0.1`). It blocks headless use. The user runs it once in Terminal, like `gh auth login`.
- Token authentication also exists: a personal API token through `circleci setting set token <token>`, or `-` to read the token from stdin, or the `CIRCLE_TOKEN` environment variable. `CIRCLE_TOKEN` wins over the stored credentials.
- `circleci setting list --json` reports `token_set`, `host`, `telemetry`, `theme`, `update_check`. `circleci auth me --json` reports the user.
- Where the CLI stores the token is not documented. The source has a `keyring` package and the snap package needs `password-manager-service`, so the macOS keychain is likely.
- DevHub never holds, stores or passes the token. It runs `circleci` and reads `token_set` to know the state. It never runs `setting set token`. The user sets the token in Terminal. A `circleci` command that prints a token does not exist in the planned set; if one is added later, `CommandKind.classify` marks it `.secret`.
- Self-hosted CircleCI server: `CIRCLE_HOST` or `circleci setting set host <host>`. Out of scope for the first version; a `ci.host` config field can come later.

### Commands DevHub needs

| Task | Command | Notes |
|---|---|---|
| Runs of a branch | `circleci run list --branch <b> --limit 10 --json` | a run is one execution of a trigger; it holds workflows, a workflow holds jobs |
| Latest run of a branch | `circleci run get --branch <b> --json` | without `--json` or `--no-interactive` it opens a picker in a terminal; always pass `--json` |
| Wait for a run | `circleci run watch [--branch <b>] [--sha <sha>] [--timeout <d>]` | exit codes: 0 succeeded, 1 failed, 6 cancelled, 7 config rejected, 8 timed out |
| Workflow | `circleci workflow get <uuid> --json` | fields: `id`, `name`, `phase`, `outcome`, `current_outcome`, `run_id`, `created_at`, `ended_at`, `jobs[]` |
| Workflows of a run | `circleci workflow list <run> --json` | |
| Job | `circleci job get <job-id> --json` | `id`, `name`, `type`, `status`, timestamps, `workflow_id`, `pipeline_id`, `executions[].steps[]` (name, type, status, duration, exit_code) |
| Job log | `circleci job output list <job-id> --json` | every step with its output; `--tail N` (default 200) only affects the text view |
| One step | `circleci job output get <job-id> --step-num <n> --strip-ansi` | raw stdout then stderr |
| Re-run | `circleci workflow rerun <uuid> [--from-failed] --json` | makes a new workflow; answer: `workflow_id`, `rerun_from`, `from_failed`. The old workflow must be finished |
| Cancel | `circleci workflow cancel <uuid> --force` and `circleci run cancel <run> --force` | `--force` skips the confirmation prompt |
| Approve | `circleci run approve <run> --job <name-or-uuid> --force --json` | approves an on-hold approval job |
| Trigger | `circleci run trigger --branch <b> [--parameter k=v] --json` | not in the first version |
| Tests | `circleci testresult list <job-id> --json` | JSONL, failures only by default |
| Artifacts | `circleci job artifact <job-id> --json` | list; `-o <dir>` downloads |
| Raw API | `circleci api <path> [-X <method>] [-f k=v] [-d <body>] [--jq <expr>]` | paths are relative to `/api/v3` unless they start with `api`, so `api/v2/...` reaches v2. Exit 4 on 4xx and 5xx |
| My runs | `circleci my runs --json` | |
| Tool state | `circleci version --json`, `circleci setting list --json` | |

Project resolution: the CLI takes `--project <slug>`; without it, it reads `.circleci/info.yml` (written by `circleci project link`), then the git remote `origin` of the working directory. So DevHub runs every command with `cwd` set to the main checkout and no `--project`. A slug is `gh/<org>/<repo>` for the GitHub OAuth integration and `circleci/<orgID>/<projectID>` for the GitHub App integration.

### How CircleCI shows up in GitHub

CircleCI reports to GitHub in two ways, and a project can have both:

| Integration | What GitHub gets | Check name | Link |
|---|---|---|---|
| GitHub App (CircleCI Checks) | one check per workflow | `<workflow name> - <8 characters of the pipeline definition ID>` | `app.circleci.com/pipelines/circleci/<orgID>/<projectID>/<pipeline number>/workflows/<workflow uuid>` |
| OAuth, "VCS Status Updates" on | one commit status per job | `ci/circleci: <job name>`; approval and no-op jobs `ci/circleci: <workflow>/<job>` | `app.circleci.com/pipelines/github/<org>/<repo>/<pipeline number>/workflows/<workflow uuid>/jobs/<job number>` |

Both links carry the workflow UUID after `/workflows/`. That UUID is the bridge: DevHub reads the GitHub checks as today, takes the UUID from `detailsUrl` or `targetUrl`, and asks `circleci workflow get <uuid> --json` for the jobs, the run ID and the approval jobs. No listing of pipelines is needed to find the right workflow. An approval job on hold is not visible as an action in GitHub at all, so `run approve` is the only way to approve from DevHub.

## Decisions

1. **On only when the project uses CircleCI.** `CIPolicy` (Domain) decides the CI provider of a project:
   - `ci.kind` in the `.devhub` config (`"circleci"`, or `"none"` to turn the detection off) wins;
   - else `.circleci/config.yml` in the main checkout (`ToolLocating.fileExists`) means CircleCI;
   - else no provider, and every screen behaves exactly as today.
   The provider is part of the effective project, next to the code host kind, so `when.ci` can hide a config action later.
2. **One Domain port, one tool.** `CIRepository` with a `CIProject` value (the checkout path and the optional slug from `ci.project`):
   - `toolState(project:) -> CIToolState` (installed, version, loggedIn);
   - `workflow(id:project:) -> CIWorkflow` (id, name, status as `CheckStatus`, runID, webURL, jobs: `[CIJob]` with id, number, name, status, isApproval, approvalRequestID when the CLI exposes it, webURL);
   - `branchRuns(branch:limit:project:) -> [CIRun]` (id, number, status, branch, revision, createdAt, webURL);
   - `jobLog(jobID:project:) -> String` (the steps joined, each step headed by its name, through `JobLogTail` so the last 200 lines show);
   - `rerun(workflowID:fromFailed:project:)`, `cancel(workflowID:project:)`, `approve(runID:job:project:)`.
   `CircleCIRepository` (Data, `DevHubData/CircleCI/`) runs the commands above through `ShellRunner` with `cwd` = checkout path, parses JSON with private DTOs (`CircleCIWorkflowParser`, `CircleCIRunParser`, `CircleCIJobOutputParser`), and maps errors to `CIError`: `notInstalled`, `oldVersion(found:)`, `notLoggedIn`, `command(message)`. `CircleCIClient` builds the argument lists as static functions, like `GhClient`, so tests check them.
   The port lives in `Ports` next to `codeHost`; `Ports.live` builds it; `Ports.mock()` and `Ports.spies()` get `MockCIRepository` and `SpyCIRepository`.
3. **The GitHub rollup stays the source of truth for the status.** The CI port adds depth, it does not replace the checks. `GhCheckParser.Context` gets `workflowUUID: String?` (parsed from the URL by `CIWorkflowLink.uuid(in:)`, a pure Domain function that finds `/workflows/<uuid>`), and `PipelineJob` gets `ciWorkflowID: String?`. With a provider and a UUID, `PullRequestDetailStore` loads the workflow once per details load and shows its jobs instead of the external status rows: the status per job, the log button, "Re-run Failed", "Cancel", and "Approve" on an on-hold approval job. Without the tool or the login, the details show one line with the command (`brew install circleci`, `circleci auth login`) and a Terminal button, as the Git request line does for `gh` and `glab`.
4. **Status words follow `CheckStatus`.** The mapping of `phase` and `outcome` (and `status` of a job) to `CheckStatus` is one table in `CircleCIStatusMapper` (Domain policy, tested): `success` / `succeeded` → `.success`, `failed` / `failing` / `error` → `.failed`, `running` → `.running`, `on_hold` → `.manual`, `canceled` → `.canceled`, `not_run` / `skipped` → `.skipped`, `queued` / `created` / `blocked` → `.pending`, others → `.other(name)`. Verify the real strings on a live project before the table is final.
5. **Everything in the command log.** `CommandKind.classify` gets a `circleci` case: `run list`, `run get`, `workflow get`, `workflow list`, `job get`, `job output`, `testresult`, `setting list`, `version`, `auth me` are `.read`; everything else is `.action`.
6. **Doctor.** `DoctorPolicy` gets `DoctorTool(name: "circleci", versionArguments: ["version"], purpose: "CircleCI workflows and jobs", installCommand: "brew install circleci && circleci auth login")`. The row warns when the version is below 1.
7. **Config.** `docs/extensions.md` gets a `ci` section: `ci.kind` (`"circleci"` | `"none"`, default: detected from `.circleci/config.yml`), `ci.project` (slug, default: resolved by the CLI from the remote). `ProjectConfig` gets `ci: CIConfig?`, `ConfigDecoding` and `ConfigMergePolicy` learn the field, the example config shows it commented out, and `Scripts/generate-example-config.sh` is run again.
8. **Not in the first version.** Triggering a run, the test results, the artifacts, a CircleCI line in the Git request line when the branch has no pull request, a status tag in worktree rows, self-hosted servers. Each is a later step with its own commit.

9. **Flaky tests get a label.** When a CircleCI job failed, DevHub reads its failed tests (`circleci testresult list <job-id> --json`, JSONL with `classname`, `name`, `result`, `run_time`, `message`) and the flaky tests of the project (`circleci api api/v2/insights/<slug>/flaky-tests`, the Insights API: `flaky-tests[]` with `classname`, `test-name`, `job-name`, `workflow-name`, `times-flaked`). `FlakyTestPolicy` (Domain) matches a failed test by `classname` and `name`. The job row gets a "flaky" tag with the count ("2 of 3 failed tests are flaky"), and the list of failed tests under the job marks each flaky one with "flaky · flaked N times". The slug for the Insights call comes from `ci.project`, else from the CircleCI link of the GitHub check (`CIWorkflowLink.parse`: `pipelines/github/<org>/<repo>/…` gives `gh/<org>/<repo>`, `pipelines/circleci/<orgID>/<projectID>/…` gives `circleci/<orgID>/<projectID>`).

## Findings of 2026-10-31 (implementation session)

- `brew install circleci` installed 1.13.0. `circleci setting list --json` answers `host` (the server), `telemetry`, `theme`, `token_set` and `update_check`; `token_set` was `false`; `circleci version --json` answers `version`, `commit`, `modified`, `latest`, `outdated`, `upgrade_command`. The Mac is not logged in (`token_set: false`), so step 1 (recorded fixtures of a live project) could not run. The fixtures in `Tests/DevHubDataTests/Fixtures/CircleCIFixture.swift` follow the field names of the CLI reference and must be checked against a live project before the ADR is accepted.
- `circleci project link` writes `.circleci/info.yml` (confirmed by the reference). `circleci api`: paths are relative to `/api/v3`; a path that starts with `api` is sent as is; exit code 4 on 4xx and 5xx.
- JSON fields per the reference: `workflow get` gives `id`, `name`, `phase`, `outcome`, `current_outcome`, `run_id`, `created_at`, `ended_at`, `jobs[]` with `id`, `name`, `phase`, `outcome`, `current_outcome`, `type`; `job get` gives `id`, `name`, `type`, `status`, `started_at`, `stopped_at`, `workflow_id`, `pipeline_id`, `executions[].steps[]`; `job output list` gives `steps[]` with `num`, `name`, `type`, `phase`, `outcome`, `exit_code`, `command`, `output`; `run list` gives `id`, `phase`, `outcome`, `current_outcome`, `branch`, `tag`, `revision`, `created_at`; `run approve` answers `run_id`, `workflow_id`, `workflow_name`, `job_id`, `job_name` and takes `--job <name-or-uuid>`, so no approval request id is needed. Neither `workflow get` nor `job get` carries a job number or a web link, so DevHub shows no per-job link; the workflow link from GitHub stays.
- The values of `phase` and `outcome` are not listed in the reference. `CircleCIStatusMapper` maps every spelling it knows (`success`, `succeeded`, `failed`, `failing`, `error`, `running`, `on_hold`, `blocked`, `canceled`, `cancelled`, `not_run`, `skipped`, `queued`, `created`, `pending`) and keeps the rest as `.other(name)`, so an unknown value shows as its own text instead of a wrong state.


## Plan

Every step: `Scripts/build.sh` prints `layers: ok`, `anonymous: ok` and the app path; `Scripts/test.sh` passes; one commit per step; the step log row of a commit lands in the next commit.

1. **Fixtures first.** On a repository with CircleCI, run with `--json` and record (anonymise, sample vocabulary): `circleci version`, `circleci setting list`, `circleci run list --branch main`, `circleci workflow get <uuid>` (one with an on-hold approval job, one failed, one succeeded), `circleci job get <id>`, `circleci job output list <id>`, `circleci workflow rerun <uuid> --from-failed`, `circleci run approve <run> --job <name>`. Also record one GitHub `statusCheckRollup` with CircleCI checks of both integration kinds. Store them in `Tests/DevHubDataTests/Fixtures/CircleCIFixture`. Write down the real `phase`, `outcome` and `status` strings in this ADR.
2. **Domain.** `CIProvider`, `CIProject`, `CIToolState`, `CIWorkflow`, `CIJob`, `CIRun`, `CIError`, `CIRepository`, `CIPolicy`, `CIWorkflowLink`, `CircleCIStatusMapper`, `CIConfig`, the `Ports` field, the `CommandKind` case. Tests for the policy, the link parser, the mapper and the command kinds.
3. **Data, Mocks, TestSupport.** `CircleCIClient`, the parsers, `CircleCIRepository`, `Ports.live`; `MockCIRepository` with `MockData`; `SpyCIRepository` in `Ports.spies()`. Parser tests over the fixtures, argument tests over the client.
4. **GitHub bridge.** `workflowUUID` in `GhCheckParser.Context`, `ciWorkflowID` in `PipelineJob`, parser tests with the recorded rollup.
5. **Pull request details.** `PullRequestDetailStore` loads the workflow when the provider is CircleCI and a job has a `ciWorkflowID`; the row models show the CircleCI jobs with the log, "Re-run Failed", "Cancel" and "Approve" (inline confirmation for cancel and approve); the not-installed and not-logged-in lines. Store tests over the spies. Feature page `docs/features/pull-requests.md`: a "CircleCI" section with the commands.
6. **Config and Doctor.** `ci.kind`, `ci.project`, the Doctor row, `docs/extensions.md`, the example config, `docs/features/settings.md`.
7. **Docs pass** (`update-docs` skill): `CHANGELOG.md`, `docs/STATUS.md` (a decision row for "CI provider detection" and the new port), this ADR (status accepted, the step log), the `code-host` and `data-layer` skills, `AGENTS.md` if the module table changes.

8. **Flaky tests.** `CIRepository.failedTests(jobID:project:)` and `flakyTests(project:)`, `FlakyTestPolicy`, the failed test list under a failed CircleCI job with the "flaky" tags, the "flaky" tag on the job row. Parser tests over the fixtures, policy tests, store and mapper tests.

## Verification on a live project

```sh
brew install circleci
circleci auth login
circleci setting list --json
cd <checkout> && circleci run list --branch main --json
circleci workflow get <uuid> --json
```

Then in DevHub: open a pull request with CircleCI checks, expand the details, read a job log, approve an on-hold job, re-run the failed jobs. Every command must appear in the Output panel. The playground repository of the owner has no CircleCI project, so these checks run on the project that needs the feature.

## Open questions

- The field names of `jobs[]` in `workflow get --json` (job id versus job number, the approval request id). Step 1 answers this.
- Whether `run approve --job` takes the job name from `workflow get` as is, or needs the approval job UUID.
- Whether `run get --branch` for a GitHub App project resolves the project from the remote without `circleci project link`. If not, the first version asks the user to run `circleci project link --project <slug>` once, or to set `ci.project`.
- The rate limit of the CLI calls. The details load makes one `workflow get` per open details; the log one `job output list` per click. No polling in the first version.

## Step log

| Commit | Step |
|---|---|
