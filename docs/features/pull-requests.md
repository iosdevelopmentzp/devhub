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

The header search filters the loaded rows by title, number, author, branches and labels. The filter menu narrows the same rows by exact values.

### Details

1. The checks or pipeline tag (click opens it in the browser), the duration, "Cancel" while it runs, and "Open in Window".
2. The checks or jobs of the last commit, failed first, then running, waiting and passed. Each row shows the status, the name (and the GitLab stage) and buttons: the log icon shows the last 200 lines of the log inside DevHub (timestamps, colours and tokens removed, with Copy Log); Retry runs a failed or cancelled job again; the globe opens it in the browser. Log and Retry need a GitHub Actions job or a GitLab job; an external status check has only the link. Without the job list (an old answer), the failed jobs show as links.
3. The description.
4. The review threads: author, text, file and line, replies. Each thread has Reply, Resolve, "Show in diff", "Open file at this line" and "Open in browser".
5. A comment box: "Comment" (⌘Return) posts a comment on the request. "Request Changes" sends the text as a review that asks for changes; it shows only on GitHub, on an open request by someone else. The text stays in the box until the post works.
6. The changed files. A click on a file shows its diff. Hover a diff line and click the bubble with a plus, or right-click the line and choose "Comment on This Line…": a box opens under the line, and "Comment" (⌘Return) starts a new review thread there. Esc closes the box. The text stays when the post fails. Threads can show under their line in the diff. A "Viewed" box folds the file and greys its name.

"Open in Window" opens the request in its own window. The window stays open after the panel closes.

### Other places that use the same data

- The Git tab header shows the request of the current branch (the request line).
- Local and remote branch rows show the open request of the branch.
- The tab bar shows a badge with the number of requests that wait for your review.
- When that number grows while the panel is closed, DevHub posts a macOS notification.

## Actions

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
| Open in browser | Opens the request page | — |
| Open in Window (context menu) | Opens the request in its own window | — |
| Copy Link, Copy Link with Title, Copy Branch Name (menu) | "Link with Title" copies the number, the title and the link | — |
| Config actions (menu) | Actions with the `pullRequests.row` placement. They get `DEVHUB_PR_NUMBER`, `DEVHUB_PR_URL` and `DEVHUB_BRANCH` (the source branch) | see [Placements](../extensions.md#33-placements) |

### Fix threads with AI

"Fix Threads with AI…" (menu) and "Fix with Claude…" (details) are shown when the request has open threads.

1. DevHub reads the details and writes the open threads into `~/.devhub/prompts/mr-<n>.md`.
2. It finds the worktree of the source branch. When there is none, it creates one.
3. It opens the terminal app from Settings in that worktree and runs `ai.reviewCommand`. The default is `claude "$(cat {prompt})"`, where `{prompt}` is the quoted path of the prompt file.

### Details actions

| Action | GitHub | GitLab |
|---|---|---|
| Read details | `gh api graphql --hostname <host> -f query=… -f owner=… -f name=… -F number=<n>` | `glab api graphql --hostname <host> -f query=… -f path=<path> -f iid=<n>` |
| Read files | `gh api --hostname <host> -X GET repos/<owner>/<name>/pulls/<n>/files?per_page=100` | `glab api --hostname <host> projects/<project>/merge_requests/<n>/diffs?per_page=100` |
| Reply in a thread | `gh api graphql …` (reply mutation) | `glab api … -X POST …/merge_requests/<n>/discussions/<id>/notes -f body=<text>` |
| Comment on the request | `gh pr comment <n> --body <text> --repo <repo>` | `glab api … -X POST …/merge_requests/<n>/notes -f body=<text>` |
| Job log | `gh api --hostname <host> --allow-escape-sequences repos/<owner>/<name>/actions/jobs/<id>/logs` | `glab api --hostname <host> projects/<project>/jobs/<id>/trace` |
| Retry one job | `gh api … -X POST repos/<owner>/<name>/actions/jobs/<id>/rerun` | `glab api … -X POST projects/<project>/jobs/<id>/retry` |
| New thread on a diff line | `gh api --hostname <host> -X POST repos/<owner>/<name>/pulls/<n>/comments -f body=… -f commit_id=<head sha> -f path=… -F line=<n> -f side=RIGHT\|LEFT` | `glab api … projects/<project>/merge_requests/<n>` (reads `diff_refs`), then `-X POST …/merge_requests/<n>/discussions` with `position[…]` fields: the three SHAs, both paths, `new_line` and, for a removed or unchanged line, `old_line` |
| Request Changes | `gh pr review <n> --request-changes --body <text> --repo <repo>` | not shown: GitLab has no such review |
| Resolve a thread | `gh api graphql …` (resolve mutation) | `glab api graphql …` (resolve mutation) |
| Open a file | Opens the file in the editor from Settings, from the worktree of the source branch or the main checkout. A double-click on a diff line opens that line | `xed --line <n> <file>` and others (see the Git page) |
| Expand All, Collapse All, Viewed, threads in the diff | Local view state only | — |

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

"Open in GitHub Instead" (or "Open in GitLab Instead") closes the form and opens the web page that creates the request.

### Reads

| Read | GitHub | GitLab |
|---|---|---|
| The list | `gh api graphql` with a search such as `repo:<path> is:pr author:@me is:open sort:updated-desc`, 50 per page | `glab api graphql` over `authoredMergeRequests`, `assignedMergeRequests` or `project.mergeRequests`, 100 per page |
| Open requests for branch tags and the review badge | The first page of "All · Open" | The first page of "All · Open" |
| The request line in the Git tab | `gh api graphql` over the pull requests of the branch and the checks of `refs/heads/<branch>` | `glab api … projects/<project>/merge_requests?source_branch=<branch>&state=all&order_by=updated_at&per_page=5` and `…/pipelines?ref=<branch>&per_page=1&order_by=id` |

Refresh rules:

- The list reads again when the tab opens and the last read is older than 60 seconds, and when the scope or state changes. A page that was read before shows at once from memory.
- The open requests read again every 5 minutes, and after every request action.
- The request line in the Git tab reads again after 90 seconds per branch.

When the tool is not logged in, the list shows the command `gh auth login --hostname <host>` (or `glab auth login --hostname <host>`) with a Copy Command button.

## Config

| Field | Effect | Reference |
|---|---|---|
| `git.remote` | The remote that gives the host and the project path | [`project.json`](../extensions.md#2-projectjson) |
| `git.host.kind` | `github` or `gitlab`. Set it for GitHub Enterprise on a custom host | [`project.json`](../extensions.md#2-projectjson) |
| `git.host.name` | The value of `--hostname` | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.targets` | The order of the target picker | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.template` | The template of a new description | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.staleDays` | Days without an update before the `stale` tag (default 14) | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.defaults.draft`, `.deleteSourceBranch`, `.squash` | The boxes of the new request form. The last two apply only on GitLab | [`project.json`](../extensions.md#2-projectjson) |
| `git.commitPrefix.pattern`, `git.ticketURL` | The ticket chip and the ticket key in a new title | [`project.json`](../extensions.md#2-projectjson) |
| `ai.reviewCommand` | The command of "Fix threads with AI" | [`project.json`](../extensions.md#2-projectjson) |
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
| `app.settings` | `ticketURLTemplate`, `editor`, `terminal` | — |

The keys start with `gitlab.` for both hosts. The "Viewed" marks, open files and open threads live in memory until DevHub quits.

## Limits

- The details read at most 100 files and 100 threads.
- The open requests come from one page (100 on GitLab, 50 on GitHub). When the project has more, branch tags and the review badge can miss some. DevHub logs this once in Recent.
- "To review" on GitHub reads only requests where your review was requested (`review-requested:@me`), then keeps the ones you have not approved. On GitLab it reads all open requests and keeps the ones by other people that are not drafts and not approved by you.
- Search and filters work only on the loaded rows.
- Auto-merge on GitHub was not seen working: the test repository has no branch protection, so the action stays hidden (`docs/STATUS.md`).
- The GitLab flows were not clicked through after the M4 rename. A later fix changed the `glab` calls: GraphQL variables `true` and `false` now go with `-F`. This path was not clicked through either (`docs/STATUS.md`).
