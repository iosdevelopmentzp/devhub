---
name: update-docs
description: "End-of-session documentation pass for DevHub: add CHANGELOG.md entries under [Unreleased], refresh docs/STATUS.md, keep docs/extensions.md equal to the config decoder, sync AGENTS.md tables and the skills with the code, commit and push. Run before finishing any session that changed files, and when the stop hook asks for it."
---

# Update Docs

Keeps history and current state readable for the next session. Six checks, in this order.

## 1. See what changed

```sh
git status --short
git diff --stat HEAD
```

## 2. `CHANGELOG.md`

Add lines under `## [Unreleased]`, grouped as `### Added`, `### Changed`, `### Fixed`, `### Removed`, `### Infrastructure`.

- One line per user-visible change. Describe behaviour, not files: "Worktrees: Prune disables when nothing is missing", not "edited WorktreesView.swift".
- Scripts, hooks, skills and docs go under `### Infrastructure`.
- Do not create a version section. Releases are cut on request only (step 6).

## 3. `docs/STATUS.md`

Update only the parts that moved:

- `Last updated` date.
- `Stage` when a milestone finished or the goal changed.
- `Screens` table: planned, mock, real, partial (with what is missing).
- `Decisions`: a new numbered line for every choice a future session must not undo. What, then why.
- `Next steps`: remove finished items, add new ones in order.
- `Known gaps`: remove fixed gaps, add new ones found during the session, including a failed push.

## 4. `docs/extensions.md`

When `DevHub/Core/Config/` changed: every new or renamed field is in the table with type, default and effect; an example under `docs/examples/devhub/` uses it.

## 5. `AGENTS.md` and skills

- `Layout` block in `AGENTS.md` when a folder or a key file was added.
- `Architecture rules` or `Conventions` when a new pattern was established.
- `ui-components` when a shared component was added or its signature changed.
- `add-feature` when the way to register a screen changed.
- `providers-and-shell` when `ShellRunner`, classification or the `Providers` bundle changed.
- `xcode-toolchain` when a command or a trap was learned.
- `panel-window` when the window code changed.
- `extensions` when the schema pieces or placements changed.
- `build-and-run` when a script or a build setting changed.

## 6. Commit and push

The remote must always hold a working app: the owner can clone it at any moment and run it. Gate every commit with a clean build and the smoke check.

```sh
APP="$(Scripts/build.sh | tail -1)"
"$APP/Contents/MacOS/DevHub" & PID=$!; sleep 3; kill -0 $PID && echo alive || echo crashed; kill $PID
git add -A
git commit -m "<type>: <what changed in plain English>"
git remote get-url origin >/dev/null 2>&1 && git push || true
```

Do this after every finished feature, not only at the end of a session. A build that prints anything but the app path, or a smoke check that says `crashed`, blocks the commit until fixed.

Commit types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`. A push that fails for access reasons is noted once in `docs/STATUS.md` under Known gaps; later commits stay local.

Release only when asked: rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD`, add a fresh empty `## [Unreleased]` above it, set `MARKETING_VERSION` in `project.pbxproj` (Debug and Release), mention the version in the commit message.

## Done when

- `git diff CHANGELOG.md` shows the new lines.
- `docs/STATUS.md` says today's date.
- Nothing in `AGENTS.md`, `docs/extensions.md` or the skills contradicts the code.
