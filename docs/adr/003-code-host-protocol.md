# ADR 003. One code host port for GitHub and GitLab

Date: 2026-10-18. Status: accepted. Milestone: M4 of ADR 001.

## Context

The first versions of DevHub read merge requests from GitLab only, through `glab`. Most projects on GitHub could not use the tab, the Git status line or the branch tags. ADR 001 section 6 planned one port with two implementations, chosen per project.

A code host is the web service that keeps the repository and its review requests: GitHub or GitLab. A review request is a "pull request" on GitHub and a "merge request" on GitLab. In the code both are `PullRequest…` types.

## Decision

1. **One port, one value per project.**
   - `CodeHostRepository` (Domain) has every operation: list, status of a branch, details, files, approve, take back an approval, draft, update the branch, re-run and cancel checks, merge, auto-merge, create, labels, resolve, reply.
   - Every method takes a `CodeHost`: the kind (`github` or `gitlab`), the host name, the repository path and the web address.
   - `CodeHostPolicy` builds the value from the web address of the remote and from `git.host.kind` and `git.host.name`. A host name with `github` is GitHub, any other host is GitLab (STATUS decision 18).
2. **Two implementations behind a router.**
   - `GhPullRequestRepository` uses `gh`: GraphQL for the list, the branch status, the details and the approval lookup; REST for the files, update-branch and new requests; `gh pr` and `gh run` for review, ready, merge and check runs.
   - `GlabPullRequestRepository` uses `glab`, as before.
   - `RoutingCodeHostRepository` sends each call to one of them by `CodeHost.kind`. `Ports.live` builds it once.
   - `GhClient` and `GlabClient` turn a failed run into `PullRequestError`: `notInstalled(tool:)` when the tool is missing, `notLoggedIn(tool:host:)` on an auth error, `command` with the trimmed error text otherwise.
3. **GitHub mapping, checked on a test repository with `gh api graphql`.**

   | DevHub field | GitHub source |
   |---|---|
   | state | `state` (`OPEN`, `MERGED`, `CLOSED`) |
   | detailed status | `isDraft`, then `mergeStateStatus`: `CLEAN`, `HAS_HOOKS`, `UNSTABLE` → mergeable; `DIRTY` → conflict; `BEHIND` → needs update; `BLOCKED` → by `reviewDecision`, then by the checks, then by open threads; other values → checking |
   | pipeline | `statusCheckRollup` of the last commit: `SUCCESS`, `FAILURE`/`ERROR`, `PENDING`/`EXPECTED` (running when a check run is `IN_PROGRESS`); the ID is the workflow run of the first failed check; the link is the failed check, else `<pull request>/checks` |
   | approvals | `latestReviews` with state `APPROVED` |
   | threads | `reviewThreads` that are not resolved; the line is `line`, else `originalLine`; `diffSide` `LEFT` is the old side |
   | permissions | merge and take back an approval need `viewerPermission` `ADMIN`, `MAINTAIN` or `WRITE`; auto-merge also needs `autoMergeAllowed` of the repository |
   | squash default | `viewerDefaultMergeMethod` is `SQUASH` |
   | branch removal default | `deleteBranchOnMerge` |

   The list uses the search API: `repo:<path> is:pr` plus `author:@me`, `review-requested:@me` or `assignee:@me`, plus the state, sorted by update. GitHub sends 50 requests per page.
4. **Words and capabilities come from the kind.**
   - `CodeHostWords` (Presentation) holds the vocabulary: "Pull Requests" and `#12` or "Merge Requests" and `!12`, "checks" or "pipeline", "Open in GitHub" or "Open in GitLab", "Update Branch" or "Rebase".
   - `CodeHostRemote` reads the remote once per project and publishes the kind. Views read the words from the environment; mappers take them as an argument (STATUS decision 21).
   - An action that the host or the repository does not allow is hidden, never shown with an error (STATUS decision 22).
5. **Config.** `git.host.*`, `git.pullRequests.*` and `ai.reviewCommand` in `docs/extensions.md`. The default description template depends on the kind. Config actions can be placed in pull request rows (`pullRequests.row`) and can be limited to one kind with `when.host`.

## Consequences

- A GitHub project gets the tab, the status line in the Git header, branch tags, the new request form, threads, files and the review badge without any config.
- Tests: recorded and anonymised `gh` answers in `GhFixture` drive the parser tests. `GhIntegrationTests` reads a real test repository when `DEVHUB_PLAYGROUND=owner/repo` is set and is skipped otherwise.
- Not checked on a live host:
  - auto-merge on GitHub: a private repository on a free plan has no branch protection and no auto-merge, so only the error path was seen;
  - the GitLab flows after the rename: they keep the tested `glab` code, and a GitLab host of the owner is needed to click through them.
- The Doctor rows for `gh` and `glab` move to M7, where the Doctor section of Settings is built.
