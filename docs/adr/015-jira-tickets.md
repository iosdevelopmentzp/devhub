# ADR 015. Jira tickets through jira-cli

Date: 2026-11-07. Status: in progress (see "Where we stopped" and the step log).

## Context

DevHub knew a ticket only as a key in a branch name: `git.commitPrefix.pattern` finds it, `git.ticketURL` turns it into a link, and the chip opens the browser. The owner asked what DevHub could do with Jira and which command line tools exist. Two tools were compared on 2026-11-07:

| | `jira-cli` (ankitpokhrel) | `acli` (Atlassian) |
|---|---|---|
| Licence and source | MIT, Go, open | closed binary |
| Version at the time | 1.7.0 (build date 2025-08-30, Homebrew bottle) | 1.3.x; a forum thread of January 2026 reports every `workitem` command failing with "unexpected error" on 1.3.11 and 1.3.13 |
| Jira editions | Cloud, Server, Data Center | Cloud only |
| Install | `brew install jira-cli` | `brew tap atlassian/homebrew-acli && brew install acli` |
| Token | `JIRA_API_TOKEN`, `~/.netrc`, or a keychain item | its own login (`acli jira auth login --web` or `--token`) |
| Output for a program | `--raw` (the Jira REST JSON), `--plain`, `--csv` | `--json` |
| Telemetry | no statement in the README; the source is open and can be checked | not found in the docs |

The owner chose `jira-cli` in the session ("Да сделай"), after the comparison above was shown with the install command.

## Decisions

### D1. `jira-cli` is the tool, with the user's own login, and DevHub never sees the token

Risk analysis per `.claude/rules/dependencies.md`:

1. What: `jira` from the Homebrew formula `jira-cli`, by ankitpokhrel, MIT licence, version 1.7.0, 19.2 MB in `/opt/homebrew/Cellar/jira-cli/1.7.0`.
2. Why: it is the one maintained open source Jira CLI that works with Cloud and Server, prints the raw REST JSON (`--raw`), and keeps the token outside DevHub. Without it, DevHub would need its own REST client with a token in its own keychain item, a new host in `Scripts/allowed-hosts.txt`, and its own login flow.
3. What it sends where: only requests to the Jira server of its config file (`~/.config/.jira/.config.yml`), with the user's token. No telemetry and no update check are documented or found in the source; nothing to turn off.
4. Pin: the user installs and updates it with Homebrew, so DevHub cannot pin it; `docs/DEPENDENCIES.md` names 1.7.0 as the checked version and Settings → Doctor shows the installed one.
5. A vendored copy is not possible for an executable; the tool is the user's install, like `gh` and `glab`.

The token lives where `jira-cli` reads it: the keychain item named `jira-cli` with the login as the account (`security add-generic-password -s jira-cli -a <login> -w <token>`), or `~/.netrc`, or `JIRA_API_TOKEN` in the shell. DevHub sets no environment for `jira`, reads no token and never records one. A menu bar app does not inherit the shell environment, so the keychain or `~/.netrc` is the way that works for DevHub.

### D2. One port, one Data folder, one tool row

`IssueTrackerRepository` (Domain) has `toolState()`, `issues(jql:project:limit:)`, `issue(key:)` and `transition(key:to:)`. `JiraIssueRepository` (`DevHubData/Jira/`) runs `jira` through `JiraClient` and `ShellRunner`, so every call lands in the command log: `jira version`, `jira me`, `jira issue list -q <jql> --raw --paginate 0:50 --order-by updated [-p <project>]`, `jira issue view <key> --raw`, `jira issue move <key> <status>`. `JiraIssueParser` maps the REST JSON (a search answer with `issues`, a plain list, or one issue) to `TrackerIssue`; `JiraDateParser` reads the Jira date format with an offset without a colon (`+0000`). `CommandKind` sorts `issue list`, `issue view`, `me`, `version`, `sprint list`, `epic list`, `project list` and `board list` as reads; everything else is an action. `jira` is in `Scripts/allowed-tools.txt` and in `DoctorPolicy.tools` (`jira version`, install `brew install jira-cli && jira init`).

`toolState()` decides in this order: `jira` not on the path → `missing`; no config file → `notConfigured`; `jira me` fails with "needs a Jira API token" → `notLoggedIn`; another failure → `failed(message)`; else `ready(version, user)`. Without a token, `jira` prints the same message with and without a config file, so the config check reads the file path, not the tool.

### D3. The tracker is config of the project, with a safe detection

`tracker` in `project.json`: `kind` (`jira` or `none`), `project` (the Jira project key, passed as `-p`), `statuses` (the "Move to" menu, default `To Do`, `In Progress`, `In Review`, `Done`), `startStatus` (the Start button, default `In Progress`), `filter` (extra JQL, added in parentheses with `AND`), `branchFormat` (default `feature/{key}-{slug}`). `TrackerSettingsPolicy` resolves it. Without `tracker.kind`, a `git.ticketURL` that contains `atlassian` or `jira` turns the tracker on, so the owner's projects need no new config for the tab to appear; `kind: none` turns it off. The JQL of the two scopes comes from `TrackerQueryPolicy`: `assignee = currentUser() AND statusCategory != Done` for Mine, `statusCategory != Done` for Project, both inside the project context that `jira-cli` adds from `-p` or its config. The order comes from `--order-by updated`, not from the JQL.

### D4. Tickets is a tool of Utils

`UtilityID.tickets` ("Tickets", `ticket`, "Filter tickets") sits after Compress Video in Utils and can be moved to the tab bar with a right-click like every tool (ADR 009, decision 71). `TicketsStore` keeps the list, the tool state, the scope (`utils.tickets.scope`), the busy keys and the error; it reads again when the panel opens, when the scope changes and after a move, and drops the list on `projectChanged` and `configChanged`. The screen: a scope picker (Mine, Project), the count, Refresh; the tool card (`TrackerToolCard`, from `TrackerToolMapper`) with the install, set-up or token command to copy and Check Again; the list in sections by status category (In progress, To do, Other, Done). A row (`TicketRow`, from `TicketRowMapper`): the type icon and tint, the key (click to copy), the summary, the status tag tinted by category, the priority tag, the assignee, the updated time; on hover Start (`Move to <startStatus>`), Copy Branch Name, Open in Browser; the context menu adds Copy Key and "Move to" with every configured status except the current one. A project without a tracker shows one message that names the config key.

### D5. The branch name of a ticket is a policy

`TrackerBranchPolicy.branchName(for:format:)` replaces `{key}` and `{slug}`; the slug is the summary in lower case ASCII with dashes, at most 40 characters cut at a dash, and a trailing dash or slash is removed, so a summary without ASCII letters gives `feature/ABC-123`. The row copies the name; creating the branch and the worktree from it is a next step (see below).

### D6. What stays out of this step

The ticket chip of the Git tab and the request rows still shows only the key and the link. Creating a branch or a worktree from a ticket, moving a ticket when a pull request is created, a comment with the request link, and notifications from Jira are next steps. A custom tab from `.devhub` scripts can do the same list with `jira issue list --raw` and a `view` directive for a tracker that is not Jira.

## Setup for a user

1. `brew install jira-cli`.
2. Create an API token in the Atlassian account settings (Security → API tokens).
3. Put it into the keychain: `security add-generic-password -s jira-cli -a <login email> -w <token>`. Or add a `~/.netrc` entry with `machine <jira host>`, `login <email>`, `password <token>`.
4. `jira init --installation cloud --server https://<site> --login <email> --project <KEY> --auth-type basic` (or plain `jira init` and answer the questions). The config lands in `~/.config/.jira/.config.yml`.
5. Open Utils → Tickets. The card shows `jira 1.7.0` and the login; "Mine" lists the open tickets assigned to you.

## Plan

| Step | What | State |
|---|---|---|
| 1 | Domain: `TrackerIssue`, `IssueStatusCategory`, `IssueScope`, `TrackerToolState`, `TrackerConfig` in `ProjectConfig`, `TrackerSettings` and `TrackerSettingsPolicy`, `TrackerQueryPolicy`, `TrackerBranchPolicy`, `IssueTrackerRepository`, `TrackerError`; `jira` in `CommandKind` and `DoctorPolicy`; tests | done |
| 2 | Data: `JiraClient`, `JiraIssueRepository`, `JiraIssueParser`, `JiraDateParser`; `Ports.live` with the config file under the home folder; mock, `MockData.issues`, spy; `jira` in `Scripts/allowed-tools.txt`; parser and client tests over `JiraFixture` | done |
| 3 | Presentation: `UtilityID.tickets`, `TicketsStore`, `TicketRowMapper`, `TicketSectionMapper`, `TrackerToolMapper`, `TicketsView`, `TicketRow`, `TrackerToolCard`; assembly, injection, harness; store and mapper tests; the tab tests know the second tool | done |
| 4 | Docs: this ADR, `docs/extensions.md` (`tracker.*`), the example `project.json` and the embedded example, `docs/features/utils.md`, `docs/features/settings.md`, `docs/DEPENDENCIES.md`, `docs/STATUS.md`, the changelog, the skills | done |
| 5 | Check on a live Jira: the `--raw` shape of `issue list` (the parser accepts a search object, a list and one issue), `-q` together with `--order-by`, `issue move` with a status that has a space, and the card states; a headless snapshot of the tab with the mock ports and with the real tool | open: needs the owner's token and `jira init` |
| 6 | The ticket chip (Git header, branch rows, request rows) shows the summary and the status of the ticket from `issue(key:)`, cached per key in a `TicketLookup` | next |
| 7 | Start creates the branch (`TrackerBranchPolicy`) and a worktree through `CreateWorktreeUseCase`, then moves the ticket; the new request form takes the summary as the title | next |
| 8 | On a created request, move the ticket to a configured status (`tracker.reviewStatus`) and comment with the request link (`jira issue comment add`) | later |
| 9 | Notifications: a poll of `assignee = currentUser() AND updated >= -10m` with the `inbox` kind, or nothing: `jira-cli` has no notification feed | later, maybe never |

## Where we stopped

Steps 1 to 4 are in the worktree branch `worktree-jira` (folder `.claude/worktrees/jira`), not on `main`. The package tests pass (2,972 tests in 521 suites). The owner's Mac has `jira-cli` 1.7.0 installed but no config file and no token, so the Tickets tab shows the "jira is not set up" card there; the private project config of the owner's main app already has its `tracker` section. The next session: run the setup for the owner (step 5), look at the tab with real data, fix what the live tool returns differently, then merge the branch into `main` and push.

## Consequences

- One `jira me` and one `jira issue list` each time the panel opens on the tab; `jira version` once per check. All in the command log.
- A project without a Jira link and without `tracker` shows a message and runs nothing.
- The `TrackerIssue` name avoids the `Issue` type of Swift Testing in the test targets.

## Step log

| Commit | What it did |
|---|---|
