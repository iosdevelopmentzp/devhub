# Pull Requests

The Pull Requests tab (⌘3) lists the pull requests (GitHub) or merge requests (GitLab) of the project. You can read the details, review threads and files, and approve, merge or update a request.

DevHub does not call the web API itself. It runs the command line tool of the host: `gh` for GitHub, `glab` for GitLab. The tool keeps the login token. On GitLab the tab title is "Merge Requests", a number is `!12` and checks are "pipeline". On GitHub the title is "Pull Requests", a number is `#12` and checks are "checks".

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/PullRequests/`, `DevHubDomain/Repositories/CodeHostRepository.swift`, `DevHubData/GitHub/`, `DevHubData/Git/Glab*`.

## How DevHub finds the host

1. DevHub reads `git remote get-url <remote>` and converts it to a web URL (`git@github.com:example/app.git` becomes `https://github.com/example/app`).
2. The host kind is `git.host.kind` when set. Without it, a host name that contains `github` means GitHub. Every other host means GitLab.
3. The host name for the tool is `git.host.name` when set, else the host of the URL.
4. The project path is the URL path, for example `example/app`.

In the commands below, `<repo>` is `example/app` on `github.com` and `<host>/example/app` on another GitHub host. `<project>` is the percent-encoded GitLab path, for example `example%2Fapp`.

## What it shows

### Toolbar

| Control | What it does |
|---|---|
| Scope | Mine (you opened them), To review, Assigned (assigned to you), All |
| State | Open, Merged, Closed, Any state. Disabled for "To review": that scope is always Open |
| Filter menu | Target branch, Labels (several at once; a request must carry every chosen label), Author, Assignee, Reviewer (a requested reviewer), "Only with conflicts", "Only ready to merge", Clear Filters. The lists hold the values of the loaded rows. Active filters show as chips under the toolbar; the ✕ on a chip removes that one filter. A click on a label tag in a row adds or removes that label in the filter |
| View menu | Detailed (every fact as a coloured tag), Calm (the same facts as grey text, colour only for what needs you), Compact (one line per request) |
| New… | Opens the new request form for the current branch of the Git tab |
| Count and refresh | The number of requests in the list and a button that reads them again |

On a narrow panel the toolbar wraps into two lines.

### List

Each row shows:

- a blue dot when the request changed since your last visit to this scope;
- the number and the title;
- the author, the age, the source and target branches, the line and file counts;
- tags: ticket chip, checks or pipeline status, `draft`, `needs your review`, `auto-merge`, `stale`, conflicts, approvals, open threads, and the labels.

A click on a row opens the details under it. When the panel is 960 points wide or more, the list and the details show side by side. A handle between them changes the width of the list.

At the end of the list, "Load N more" reads the next page. N is the page size of the host: 50 on GitHub, 100 on GitLab.

The search field in the toolbar filters the loaded rows by title, number, author, branches and labels. The filter menu narrows the same rows by exact values.

### Details

1. The checks or pipeline tag (click opens it in the browser), the duration, "Cancel" while it runs, and "Open in Window".
2. The checks or jobs of the last commit, grouped by stage (GitLab) or by workflow (GitHub). A group header shows the state of the group; inside, failed jobs come first, then running, waiting and passed. Each row shows the status, the name, how long the job ran, an "allowed to fail" mark, and, when it failed, a folded "reason" that opens the failure message (GitLab) or the check title (GitHub). Buttons: the log icon shows the last 200 lines of the log inside DevHub (timestamps, colours and tokens removed, with Copy Log); Retry runs a failed or cancelled job again; the globe opens it in the browser. Log and Retry need a GitHub Actions job or a GitLab job; an external status check has only the link. Without the job list (an old answer), the failed jobs show as links. With CircleCI (see the CircleCI section), a check that points at a CircleCI workflow is replaced by the jobs of that workflow.
3. The review block: "Approved by", "Changes requested", "Waiting for" (a requested reviewer without an answer) and "Assigned to", one tag per person; "you" stands for your own account. An open request without reviewers says "none requested". GitHub takes the latest review of each person and the review requests; GitLab takes the review state of each reviewer. Under it, "Reviewers" and "Assignees" menus list the people of the project with a check mark on the current ones; a click adds or removes that person. The menus show on an open request that you wrote or that you can merge. Each change shows as an operation card and refreshes the list. Under the menus, "Explain" asks Claude Code or Copilot CLI to explain the request (see "Write with AI and Explain").
4. The description.
5. The review threads: author, time, file and line, the full text with inline markdown (selectable), and the replies behind "N replies". Each thread has Reply, Resolve, "Show in diff", "Open file at this line" and "Open in browser".
6. A comment box: "Comment" (⌘Return) posts a comment on the request. "Request Changes" sends the text as a review that asks for changes; it shows only on GitHub, on an open request by someone else. The text stays in the box until the post works.
7. The changed files. By default every file is listed. The eye-slash button of a file hides it in the requests of this project (saved, `gitlab.hiddenFiles.<project>`); a line under the header names the tests, Xcode project files and lock files of the request (`HiddenFilePolicy.suggestedPatterns`) and "Hide Them" hides them, only on that click. Files that match `git.pullRequests.hiddenFiles` in `project.json` are hidden too. Groups from `git.pullRequests.fileGroups` show as chips under the header, one per group with a match ("Tests 12"): a click hides or shows the files of that group for this request, a group with `hidden: true` starts hidden, and the hidden tag of such a file names its group. The hide suggestion skips files that belong to a group. "Show N hidden" in the header lists the hidden files with a "hidden" tag, "Hide N" hides them again, per request until DevHub quits; the eye button of a file you hid shows it again for good. The counts in the header follow the listed files. A click on a file shows its diff. Inside a changed pair of lines the words that differ get a stronger background (the removed and added lines of one block are paired in order; lines that share less than 40 % get no marks). The segmented control in the header switches every diff between Unified and Side by Side (the file before the change on the left, after it on the right, row by row); the choice is saved. Side by side needs 600 points of width: a narrower view keeps the unified diff and the control says so in its hint. Hover a diff line and click the bubble with a plus, or right-click the line and choose "Comment on This Line…": a box opens under the line, and "Comment" (⌘Return) starts a new review thread there. Esc closes the box. The text stays when the post fails. Threads can show under their line in the diff; a thread opened there shows its replies at once. "Expand All" opens the listed files that are not viewed. A "Viewed" box folds the file and greys its name. The text-lines button of a modified or renamed file shows the whole file at the last commit of the request with the changes in place (DevHub reads the file from the host once per request); a second click shows only the changed parts again. The compass button opens the whole file in the browser at the last commit; "Open in Browser at This Line" in the menu of a diff line opens it at that line.

"Open in Window" opens the request in its own window (1120 × 760 at first, at least 1000 × 560). The window stays open after the panel closes. Its left side is a file sidebar: "N of M viewed" with a bar, a filter field, the group chips, and one row per listed file with its letter, name, folder, counts, open threads, a "changed since review" mark and the viewed circle (a click on the circle marks the file). A click on a row opens the diff of that file and scrolls to it; the arrows at the top go to the previous and next file. The context menu of a row has Show Diff, Mark as Viewed, Open in Editor, Open in Browser, Copy Path and Copy File Name. In the split layout of the tab the details header repeats the author, the dates, the branches, the counts and the tags of the request.

### Changed since your review

Settings → Pull Requests → "Remember what I reviewed" (on by default) lets DevHub compare a request with your last review. Everything stays on this Mac; DevHub asks the host for nothing extra.

1. DevHub saves a fingerprint of the diff of each file when you approve, post a comment, ask for changes, or mark every file as viewed. It can do this only for a request whose details you opened, because the fingerprint comes from the diff you saw. The fingerprint counts only the added and removed lines, so a rebase that moves a file's changes without editing them does not count as a change.
2. When the request has new commits, a line above the files says "N files changed since your review <time>". Each such file has an orange "changed since review" tag. "Show Only These" lists only them; "Show All Files" brings the rest back. With no change the line is green: "No file changed since your review <time>".
3. "Viewed" marks are saved with the fingerprint of the file. They come back after a restart and drop off a file whose diff changed.
4. "Forget" on the line removes what DevHub saved for that request. Turning the setting off removes it for every project.
5. DevHub keeps the last 200 requests per project.

### Other places that use the same data

- The Git tab header shows the request of the current branch (the request line).
- Local and remote branch rows show the open request of the branch.
- The tab bar shows a badge with the number of requests that wait for your review.
- When that number grows while the panel is closed, DevHub posts a macOS notification ("2 pull requests wait for your review") and a Recent row; a click on either opens the "To review" scope.
- Changes of your own open requests between two reads go to the Recent list on Home and, while the panel is closed, to a macOS notification (one switch per kind in Settings → Notifications; a click opens the request): "#12 approved by alex" (new approvers, not you), "Changes requested on #12 by sam" (a new review that asks for changes), "Checks failed on #12" (the checks or pipeline turned to failed), "sam commented on #12" (new comments by someone else, with their authors; your own comments are silent; "2 new comments on #12" when the host gives no authors), "#12 merged" and "#12 closed without a merge". A request that left the open list gets one status read of its branch (the request line read) to learn its final state; a request that is still open (for example beyond the first page) is silent. A new request of yours and the first read after a start or a project switch report nothing. A refresh after your own action in DevHub updates the baseline without a report.

## Actions

An action below shows an operation card in the tray at the bottom of the tab: the steps with their state and time while it runs, and after a failure the failed step, the lines that explain it, Retry (when the action can run again), Copy Error and Full Output. See [Operations](output.md#operations).

### Request actions

The row shows the main actions on hover. The overflow menu and the context menu show the rest. An action is shown only when the request is open and the host allows it for you.

| Action | When it is shown | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|---|
| Approve | Someone else's request that you have not approved | `gh pr review <n> --approve --repo <repo>` | `glab api --hostname <host> -X POST projects/<project>/merge_requests/<n>/approve` |
| Revoke Approval | You approved it. GitHub: only with write access | `gh api graphql …` (dismisses your review with the message "Approval taken back") | `glab api … -X POST …/merge_requests/<n>/unapprove` |
| Merge… | Ready to merge and you may merge. Asks first, with "Squash" and "Delete source branch" boxes | `gh pr merge <n> --squash\|--merge [--delete-branch] --repo <repo>` | `glab api … -X PUT …/merge_requests/<n>/merge -f squash=<bool> -f should_remove_source_branch=<bool>` |
| Merge When Checks Pass… / Merge When Pipeline Passes… | Checks still run, auto-merge is allowed and not set. Asks first | `gh pr merge <n> … --auto --match-head-commit <sha> --repo <repo>` | `glab api graphql …` (auto-merge mutation with the head SHA) |
| Cancel Auto-Merge | Auto-merge is set | `gh pr merge <n> --disable-auto --repo <repo>` | `glab api … -X POST …/merge_requests/<n>/cancel_merge_when_pipeline_succeeds` |
| Mark as Ready | Draft | `gh pr ready <n> --repo <repo>` | `glab api graphql …` (draft mutation) |
| Mark as Draft | Not a draft | `gh pr ready <n> --undo --repo <repo>` | `glab api graphql …` (draft mutation) |
| Update Branch from `<target>` / Rebase onto `<target>` | Always for an open request. GitHub merges the target into the source on the server. GitLab rebases the source on the server | `gh api --hostname <host> -X PUT repos/<owner>/<name>/pulls/<n>/update-branch` | `glab api … -X PUT …/merge_requests/<n>/rebase` |
| Re-run Failed Checks / Retry Pipeline | The last checks failed | `gh run rerun <id> --failed --repo <repo>` | `glab api … -X POST projects/<project>/pipelines/<id>/retry` |
| Cancel Checks / Cancel Pipeline | The checks run | `gh run cancel <id> --repo <repo>` | `glab api graphql …` (pipeline cancel mutation) |

After each action DevHub logs the result in Recent and reads the list again.

### Branch and copy actions

| Action | What it does | Command |
|---|---|---|
| Build & Run… | Opens the simulator, profile and device ID picker, then builds the source branch | see the Simulators tab |
| Build & Run on Target Now (menu) | Builds the source branch on the target simulator | see the Simulators tab |
| Create Worktree | For a source branch without a worktree | see the Worktrees page |
| Open Worktree in Terminal | For a source branch with a worktree | `open -a <terminal> <path>` |
| Use This Checkout in Git Tab (menu) | Shows the Git tab on that worktree | — |
| Switch to Branch (menu) | Only when the branch exists locally and the main checkout is clean | `git switch <branch>` |
| Watch, Stop Watching (menu) | Watches a request by someone else: DevHub reads the list every minute and reports an approval, a request for changes, failed checks, a new comment and the merge or close as a "Watched" event and a notification. The row shows a "watching" tag. The watch ends when the request is merged or closed | — |
| Open in browser | Opens the request page | — |
| Open in Window (context menu) | Opens the request in its own window | — |
| Copy Link, Copy Link with Title, Copy Branch Name (menu) | "Link with Title" copies the number, the title and the link | — |
| Config actions (menu) | Actions with the `pullRequests.row` placement. They get `DEVHUB_PR_NUMBER`, `DEVHUB_PR_URL` and `DEVHUB_BRANCH` (the source branch) | see [Placements](../extensions.md#33-placements) |

### Fix threads with AI

"Fix Threads with AI" (menu) and "Fix with AI" (details) are shown when the request has open threads. Both offer Claude Code and Copilot CLI.

1. DevHub reads the details and writes the open threads into `~/.devhub/prompts/mr-<n>.md`.
2. It finds the worktree of the source branch. When there is none, it creates one.
3. It opens the terminal app from Settings in that worktree and runs the command of the chosen tool from `ai.commands` (`claude` or `copilot`). The defaults are `claude "$(cat {prompt})"` and `copilot -i "$(cat {prompt})"`, where `{prompt}` is the quoted path of the prompt file.

### Write with AI and Explain

DevHub runs Claude Code or Copilot CLI once, without a terminal, and puts the answer into DevHub. Each button uses the tool from Settings → AI usage ("Write with AI and Explain use"); the arrow next to it picks the other tool for one run. Each run is an operation card with "<tool> is writing…" and Stop. A failure keeps the card red with the reason from the tool, for example a missing install or a policy of the account.

| Button | Where | What the tool gets | What DevHub does with the answer |
|---|---|---|---|
| Write with AI | New request form | The diff of `<remote>/<target>...<branch>`, the commit subjects of the branch, the current title, the description (used as the template), the branch names, the host word ("pull request" or "merge request") | The first line becomes the title, the rest the description |
| Explain | Details, under the review block | The title, the description and the diff of every changed file of the request. After a review with changed files, the names of those files | Shows the answer under the button with the sections "What it changes", "Risky places", "Changed since my review" (only after a review) and "What to check". "Explain Again" runs it again, "Hide" removes it |
| Write with AI | Commit box of the Git tab | See the [Git page](git.md#changes) | The commit message |

How it runs:

1. DevHub writes the prompt to a file in the temporary folder of the app (`DevHub/AI/prompt-<id>.md`) and removes it after the run.
2. It runs the command of the tool from `ai.textCommands` with `/bin/sh -c` in the main checkout. The PATH gets `~/.local/bin`, `~/.claude/local`, `~/.npm-global/bin`, `/opt/homebrew/bin` and `/usr/local/bin` first.
3. The defaults are `claude -p "$(cat {prompt})" --output-format text` and `copilot -p "$(cat {prompt})" -s --no-ask-user --no-color --stream off`. `{prompt}` becomes the quoted path of the prompt file.
4. DevHub removes code fences and terminal colour codes from the answer. Exit code 127 means "not installed". Another failure shows the last 6 lines of the output.
5. A diff longer than 60,000 characters is cut, with a note to the tool about the rest. A file whose diff the host did not send is described by its counts only.

The command lands in the Output panel like every other command. The prompt holds the diff, so it goes to the AI service of the chosen tool.

### Details actions

| Action | GitHub | GitLab |
|---|---|---|
| Read details | `gh api graphql --hostname <host> -f query=… -f owner=… -f name=… -F number=<n>` | `glab api graphql --hostname <host> -f query=… -f path=<path> -f iid=<n>` |
| Read files | `gh api --hostname <host> -X GET repos/<owner>/<name>/pulls/<n>/files?per_page=100` | `glab api --hostname <host> projects/<project>/merge_requests/<n>/diffs?per_page=100` |
| Reply in a thread | `gh api graphql …` (reply mutation) | `glab api … -X POST …/merge_requests/<n>/discussions/<id>/notes -f body=<text>` |
| Comment on the request | `gh pr comment <n> --body <text> --repo <repo>` | `glab api … -X POST …/merge_requests/<n>/notes -f body=<text>` |
| Job log | `gh api --hostname <host> --allow-escape-sequences repos/<owner>/<name>/actions/jobs/<id>/logs` | `glab api --hostname <host> projects/<project>/jobs/<id>/trace` |
| Read a file at the last commit (whole file) | `gh api --hostname <host> -H "Accept: application/vnd.github.raw+json" repos/<owner>/<name>/contents/<path>?ref=<head sha>` | `glab api --hostname <host> projects/<project>/repository/files/<path>/raw?ref=<head sha>` |
| Retry one job | `gh api … -X POST repos/<owner>/<name>/actions/jobs/<id>/rerun` | `glab api … -X POST projects/<project>/jobs/<id>/retry` |
| New thread on a diff line | `gh api --hostname <host> -X POST repos/<owner>/<name>/pulls/<n>/comments -f body=… -f commit_id=<head sha> -f path=… -F line=<n> -f side=RIGHT\|LEFT` | `glab api … projects/<project>/merge_requests/<n>` (reads `diff_refs`), then `-X POST …/merge_requests/<n>/discussions` with `position[…]` fields: the three SHAs, both paths, `new_line` and, for a removed or unchanged line, `old_line` |
| Request Changes | `gh pr review <n> --request-changes --body <text> --repo <repo>` | not shown: GitLab has no such review |
| People of the project (once per project, when details open) | `gh api --hostname <host> -X GET repos/<owner>/<name>/assignees?per_page=100` | `glab api --hostname <host> projects/<project>/members/all?per_page=100` (active members) |
| Add or remove a reviewer | `gh pr edit <n> --add-reviewer <login> --remove-reviewer <login> --repo <repo>` | `glab mr update <n> --reviewer=+<login> --reviewer=!<login> --repo <project web address>` |
| Add or remove an assignee | `gh pr edit <n> --add-assignee <login> --remove-assignee <login> --repo <repo>` | `glab mr update <n> --assignee=+<login> --assignee=!<login> --repo <project web address>` |
| Resolve a thread | `gh api graphql …` (resolve mutation) | `glab api graphql …` (resolve mutation) |
| Open a file | Opens the file in the editor from Settings, from the worktree of the source branch or the main checkout. A double-click on a diff line opens that line | `xed --line <n> <file>` and others (see the Git page) |
| Open a file in the browser | Opens the file at the last commit of the request (`<repository>/blob/<sha>/<path>` on GitHub, `<repository>/-/blob/<sha>/<path>` on GitLab), with `#L<n>` from the menu of a diff line | — |
| Inbox (Notifications screen) | `gh api --hostname <host> -X GET notifications?per_page=50`, then `gh api -X GET <latest_comment_url>` for up to 10 mention or comment threads | `glab api --hostname <host> todos?state=pending&per_page=50` |
| Mark an Inbox item as done | `gh api --hostname <host> -X PATCH notifications/threads/<id>` | `glab api --hostname <host> -X POST todos/<id>/mark_as_done` |
| Expand All, Collapse All, Viewed, threads in the diff | Local view state; Viewed is saved on this Mac (see "Changed since your review") | — |

### New request form

The form opens from the Git header, a local branch row, or "New…" in the toolbar. DevHub fills the fields with these values:

| Field | Start value |
|---|---|
| Into (target) | The first of `git.pullRequests.targets` that exists on the remote. Without the field: `dev`, the base branch, `develop`, `main`, `master`. The other remote branches follow, sorted |
| Title | When the branch name has a ticket key: `<key>: <subject of the last commit>`. Without a key: the subject of the last commit |
| Description | The template file when it exists and is not empty. Otherwise `Ticket: <key>` and one line per commit subject, oldest first (`git log --format=%s -n 50 <remote>/<target>..<branch>`) |
| Draft | `git.pullRequests.defaults.draft` |
| Delete source branch after merge, Squash | `git.pullRequests.defaults.*`. GitLab only: GitHub does not take these options when a request is created, so the form hides them |
| Labels | The labels of the project: `gh label list --json name --limit 200 --repo <repo>` or a `glab api graphql` labels query |

Create runs these steps:

1. When the branch has no upstream, or has commits to push, DevHub pushes first: `git push -u <remote> <branch>` or `git push`.
2. GitHub: `gh api --hostname <host> -X POST repos/<owner>/<name>/pulls -f head=<branch> -f base=<target> -f title=… -f body=… -F draft=<bool>`, then `-X POST repos/<owner>/<name>/issues/<n>/labels -f labels[]=…` for the labels.
3. GitLab: `glab api --hostname <host> -X POST projects/<project>/merge_requests -f source_branch=… -f target_branch=… -f title=… -f description=… -f remove_source_branch=<bool> -f squash=<bool> [-f labels=a,b]`. A draft gets the title prefix `Draft: `.
4. DevHub shows the new request in the Pull Requests tab.

The Create button says "Push & Create" when step 1 is needed.

"Write with AI" in the form header fills the title and the description from the diff of the branch (see "Write with AI and Explain"). Its operation card shows in the tray at the bottom of the tab.

"Open in GitHub Instead" (or "Open in GitLab Instead") closes the form and opens the web page that creates the request.

### Reads

| Read | GitHub | GitLab |
|---|---|---|
| The list | `gh api graphql` with a search such as `repo:<path> is:pr author:@me is:open sort:updated-desc`, 50 per page | `glab api graphql` over `authoredMergeRequests`, `assignedMergeRequests` or `project.mergeRequests`, 100 per page |
| Open requests for branch tags and the review badge | The first page of "All · Open" | The first page of "All · Open" |
| The request line in the Git tab | `gh api graphql` over the pull requests of the branch and the checks of `refs/heads/<branch>` | `glab api … projects/<project>/merge_requests?source_branch=<branch>&state=all&order_by=updated_at&per_page=5` and `…/pipelines?ref=<branch>&per_page=1&order_by=id` |

Refresh rules:

- The list reads again when the tab opens and the last read is older than 60 seconds, and when the scope or state changes. A page that was read before shows at once from memory.
- The open requests read again every 5 minutes (every 2 minutes while the panel is closed, so that the reports of your own requests arrive sooner), and after every request action.
- The request line in the Git tab reads again after 90 seconds per branch.

When the tool is not logged in, the list shows the command `gh auth login --hostname <host>` (or `glab auth login --hostname <host>`) with a Copy Command button.

## CircleCI

Source: `Packages/DevHubKit/Sources/DevHubData/CircleCI/`, `DevHubDomain/Policies/CIPolicy.swift`, `CIWorkflowLink.swift`, `CircleCIStatusMapper.swift`, `FlakyTestPolicy.swift`, `DevHubPresentation/Features/PullRequests/PullRequestDetailStore.swift`, `PipelineJobRowMapper.swift`. Design: [ADR 006](../adr/006-circleci-integration.md).

A GitHub project can run its checks on CircleCI. GitHub then shows one check per workflow (the GitHub App, `<workflow> - <id>`) or one status per job (the OAuth integration, `ci/circleci: <job>`), each with a link that carries the workflow UUID (`…/workflows/<uuid>` or `…/workflow/<uuid>/job/<uuid>`). The GitHub checks stay the source of truth for the state. The `circleci` tool adds the jobs, the logs, the actions and the test results.

### When it is on

1. `ci.kind` in `project.json`: `"circleci"` turns it on, `"none"` turns it off.
2. Without `ci.kind`: on when `.circleci/config.yml` exists in the main checkout.
3. The `circleci` tool must be installed (`brew install circleci`, version 1.0 or newer) and logged in (`circleci auth login`). When it is not, the details show one line with the command and a "Run in Terminal" button, and the CircleCI checks stay links.

### What it shows

1. When the details load, DevHub checks the tool once per project (`circleci version --json`, `circleci setting list --json`), then reads every workflow that a check points at (`circleci workflow get <uuid> --json`). The check rows that point at the workflow are replaced by one group per workflow, named after it and marked "CircleCI": the jobs with their state, failed first; a job that waits for approval says "waiting for approval".
2. A failed job has a folded "N failed tests" next to its state (`circleci testresult list <job> --json`, at most 5 jobs per workflow). A click opens the list: the test name (click to copy) and, behind its own chevron, its message. DevHub keeps what is open until the project changes. When at least one test failed, DevHub reads the flaky tests of the project once (`circleci api api/v2/insights/<slug>/flaky-tests`). A failed test that is in that list gets a "flaky · flaked N times" tag, and the job row gets a "flaky" tag, or "N of M flaky" when only some of the failed tests are flaky. The slug comes from `ci.project`, else from the CircleCI link of the check (`gh/<owner>/<repo>` or `circleci/<org id>/<project id>`), else from a GitHub remote (`gh/<owner>/<repo>`); without a slug there is no flaky list.
3. The log button of a finished job shows the last 200 lines of its steps (`circleci job output list <job> --json`), each step under a `== <step name>` header with the exit code of a failed step.
4. The group header has "Re-run Failed" and "Re-run All" when the workflow is finished, and "Cancel" (inline confirmation) while it runs or waits. The retry button of a failed job runs the failed jobs of its workflow again. A job that waits for approval has an Approve button with an inline confirmation. After an action DevHub reads the request again; a re-run makes a new workflow, which shows when GitHub reports it.
5. While the workflow is read, the GitHub rows say "Reading the CircleCI workflow…"; when the read fails, they say "CircleCI: <error>" and the failure is in Recent.

### Previous runs

DevHub keeps every finished CircleCI workflow it reads for a request: the workflow, the state of its jobs and the failed tests with their messages. A re-run makes a new workflow, so the failed run moves under "Previous CircleCI runs N" below the jobs, folded by default. A row shows the workflow name, its state, when DevHub first read it and the number of failed jobs and tests. A click on the chevron lists the failed jobs and their tests; the message of a test opens behind its own chevron. "Forget" removes the saved runs of the request.

The runs are saved per project and request (`gitlab.ciHistory.<project>.<number>`), at most 20 per request, at most 50 tests per job and 4000 characters per message. DevHub saves a run only when it reads it: when the details are open, or when the auto re-run below runs it again.

### Auto re-run

"Auto re-run" on the line of the checks title runs the failed jobs of a CircleCI workflow again each time the workflow fails. The menu sets the most re-runs: 3, 5, 10 or 20. The button then shows "Auto re-run 2 of 10"; a click stops it.

1. DevHub checks the request at once and then every minute while DevHub runs (the checks of the request, then `circleci workflow get <uuid> --json` for each CircleCI workflow), also when the panel is closed. The plans are saved per project (`gitlab.autoRerun.<project>`), so they go on after DevHub starts again.
2. A failed workflow is saved under "Previous CircleCI runs", then runs again with `circleci workflow rerun <uuid> --from-failed`. Each re-run of a workflow counts as one try. Recent and a notification say "Re-run 2 of 10: <workflow> of #N".
3. The workflow that ran again waits up to 10 minutes for its new workflow to show in GitHub. After that DevHub stops waiting for it.
4. The plan ends when every workflow passes ("Checks of #N passed"), when a workflow is cancelled ("Auto re-run of #N stopped") or when a workflow fails after the last try ("Auto re-run of #N gave up"). Each end is a line in Recent and a notification of the "Checks of my requests" kind.
5. A running workflow or one that waits for approval keeps the plan waiting. A read error goes to Recent once until it changes.

### Commands

Every command runs in the main checkout, so the tool resolves the project from `.circleci/info.yml` or the remote `origin`. With `ci.project` or a slug from the check link, `run list` and `run approve` also get `--project <slug>`. The other commands (`workflow`, `job`, `testresult`) take an ID and have no such flag.

| Action | Command |
|---|---|
| Tool state | `circleci version --json`, `circleci setting list --json` |
| Workflow and jobs | `circleci workflow get <uuid> --json` |
| Failed tests of a job | `circleci testresult list <job> --json` |
| Flaky tests of the project | `circleci api api/v2/insights/<slug>/flaky-tests` |
| Job log | `circleci job output list <job> --json` |
| Re-run | `circleci workflow rerun <uuid> [--from-failed] --json` |
| Cancel | `circleci workflow cancel <uuid> --force` |
| Approve | `circleci run approve <run> --job <job name> --force --json` |

The reads are `.read` in the Output panel; re-run, cancel and approve are actions. The fixtures of the parsers follow the CLI reference of October 2026 and still have to be checked on a live project (ADR 006).

## Config

| Field | Effect | Reference |
|---|---|---|
| `git.remote` | The remote that gives the host and the project path | [`project.json`](../extensions.md#2-projectjson) |
| `git.host.kind` | `github` or `gitlab`. Set it for GitHub Enterprise on a custom host | [`project.json`](../extensions.md#2-projectjson) |
| `git.host.name` | The value of `--hostname` | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.targets` | The order of the target picker | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.template` | The template of a new description | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.staleDays` | Days without an update before the `stale` tag (default 14) | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.hiddenFiles` | Patterns of the files that the details hide until "Show N hidden" (default: none) | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.defaults.draft`, `.deleteSourceBranch`, `.squash` | The boxes of the new request form. The last two apply only on GitLab | [`project.json`](../extensions.md#2-projectjson) |
| `git.commitPrefix.pattern`, `git.ticketURL` | The ticket chip and the ticket key in a new title | [`project.json`](../extensions.md#2-projectjson) |
| `ai.commands` | The command of each AI tool for "Fix Threads with AI" | [`project.json`](../extensions.md#2-projectjson) |
| `ai.textCommands` | The command of each AI tool for "Write with AI" and "Explain" | [`project.json`](../extensions.md#2-projectjson) |
| `ci.kind`, `ci.project` | CircleCI on or off, and the project slug for `--project` of `run list` and `run approve` and for the flaky test list | [`project.json`](../extensions.md#2-projectjson) |
| Actions with `pullRequests.row` | Items in the row menus | [Placements](../extensions.md#33-placements) |
| `when.host` | Shows an action only for GitHub or only for GitLab | [Actions](../extensions.md#3-actions) |
| `refresh: ["pullRequests"]` | Reads the list, the open requests and the request line again after an action | [Actions](../extensions.md#3-actions) |

## Saved preferences

| Key | What it keeps | Default |
|---|---|---|
| `gitlab.scope` | The scope | Mine |
| `gitlab.state` | The state | Open |
| `gitlab.filter` | Target branch, labels, author, assignee, reviewer, conflicts, ready to merge | no filter |
| `gitlab.listStyle` | Detailed, Calm or Compact | Detailed |
| `gitlab.listFraction` | The width of the list in the side-by-side layout | 0.42 |
| `gitlab.seenAt.<scope>` | The time of your last visit to each scope (the blue "new" dot) | — |
| `gitlab.watched.<project>` | The requests you watch | none |
| `gitlab.autoRerun.<project>` | The CircleCI auto re-run plans: request, most re-runs, re-runs done, workflows already run again | none |
| `gitlab.ciHistory.<project>.<number>` | The earlier CircleCI workflows of a request with their failed tests | none |
| `gitlab.hiddenFiles.<project>` | The file paths you hid in the details (eye-slash button or "Hide Them") | none |
| `gitlab.reviews.<project>` | Your last review of each request: the time and a fingerprint of the diff of each file, and the Viewed marks with their fingerprints (200 requests at most) | none |
| `app.settings` | `ticketURLTemplate`, `editor`, `terminal` | — |

The keys start with `gitlab.` for both hosts. Open files and open threads live in memory until DevHub quits. The "Viewed" marks are saved in `gitlab.reviews.<project>` while "Remember what I reviewed" is on, else they live in memory too.

## Limits

- The details read at most 100 files and 100 threads.
- The open requests come from one page (100 on GitLab, 50 on GitHub). When the project has more, branch tags and the review badge can miss some. DevHub logs this once in Recent.
- "To review" on GitHub reads only requests where your review was requested (`review-requested:@me`), then keeps the ones you have not approved. On GitLab it reads all open requests and keeps the ones by other people that are not drafts and not approved by you.
- Search and filters work only on the loaded rows.
- Auto-merge on GitHub was not seen working: the test repository has no branch protection, so the action stays hidden (`docs/STATUS.md`).
- The GitLab flows were not clicked through after the M4 rename. A later fix changed the `glab` calls: GraphQL variables `true` and `false` now go with `-F`. This path was not clicked through either (`docs/STATUS.md`).
