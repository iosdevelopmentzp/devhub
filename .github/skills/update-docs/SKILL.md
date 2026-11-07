---
name: update-docs
description: "End-of-session documentation pass for DevHub: CHANGELOG.md entries under [Unreleased], docs/STATUS.md, the ADR 001 step log (a commit's row lands in the next commit), docs/extensions.md and the example config against the decoder, docs/features pages, docs/ARCHITECTURE.md, AGENTS.md and the skills against the code, the anonymity check, then a local commit. Run before finishing any session that changed files, and when the stop hook asks for it."
---

# Update Docs

The next session starts from these files. Keep them true. Work in this order. Every text follows the plain English
rule in `AGENTS.md`: short sentences, common words, no idioms, exact technical terms.

## 1. See what changed

```sh
git status --short
git diff --stat HEAD
git log --oneline -5
```

## 2. `CHANGELOG.md`

Add lines under `## [Unreleased]`, in the groups `### Added`, `### Changed`, `### Fixed`, `### Removed`,
`### Infrastructure`.

- One line per user-visible change. Describe behaviour, not files: "Worktrees: Prune is off when nothing is
  missing", not "edited WorktreesView.swift".
- Scripts, hooks, skills, rules and docs go under `### Infrastructure`.
- Never create a version section. A release is cut only when the owner asks.

The stop hook (`Scripts/ai/check-changelog.sh`) blocks a session that changed `DevHub/`, `Packages/`, `Scripts/`,
`.github/` or `.claude/rules/` while `CHANGELOG.md` did not change.

## 3. `docs/STATUS.md`

Change only the parts that moved:

- `Last updated` date and milestone.
- `Stage` when a milestone finished.
- `Screens` table: planned, mock, real, partial (say what is missing), hidden. Say how the screen was checked
  (headless snapshot, debug switch, tests only).
- `Decisions`: a new numbered entry for every choice a later session must not undo. What, then why. Never renumber.
- `Next steps`: remove finished items, add new ones in order.
- `Known gaps`: remove fixed gaps, add new ones. A bug that a test pins goes here until its own fix.

## 4. ADR 001 step log

`docs/adr/001-port-from-main-devhub.md`, section "Step log": one row per commit with the short hash, the milestone and
what the commit did.

A commit cannot hold its own hash. So the row of a commit lands in the next commit:

1. Commit the step.
2. Read its hash with `git log --oneline -1`.
3. Add the row `| \`<hash>\` | M<n> | <what it did> |` and keep it in the working tree. It goes into the next step
   commit, or into a small `docs:` commit at the end of the session.

An ADR that needs a new decision gets a new numbered file (`docs/adr/00N-<topic>.md`). Never rewrite an accepted
decision in place; add a dated note under it.

## 5. Config schema

When `DevHubDomain/Models/Config/`, `ConfigDecoding`, `ConfigMergePolicy` or a placement changed:

- `docs/extensions.md`: every new or renamed field with type, default and effect. The file must match the decoder.
- `docs/examples/devhub/` uses the field once. Then run `Scripts/generate-example-config.sh` (it rewrites
  `ExampleConfig.swift`) and `Scripts/test.sh`.
- `docs/adr/002-config-system.md` when the shape of the config system changed.

## 6. Feature pages

`docs/features/<tab>.md` holds one page per tab: what it shows, every action and what it runs, the config fields it
reads, saved preferences, limits. Update the page of every tab whose behaviour changed. A new tab gets a new page.

## 7. Architecture, AGENTS.md and skills

| File | Update when |
|---|---|
| `docs/ARCHITECTURE.md` | a module rule, a folder, a factory or a naming pattern changed; the port and use case counts in sections 2 and 7 |
| `AGENTS.md` | a command, a folder or a key file changed (`Layout` table), a convention was set, a skill was added or removed (`Skills` list) |
| `.claude/rules/*.md` | the short form of a rule in `ARCHITECTURE.md` changed |
| `add-feature` | the way to register a tab or wire a store changed |
| `add-use-case` | use cases, lookups or `AppEvent` rules changed |
| `data-layer` | `ShellRunner`, the command log, a runner, `Ports.live` or the Data folders changed |
| `code-host` | the code host port, `gh` or `glab` handling changed |
| `testing` | spies, `StoreHarness`, fixtures or `Scripts/test.sh` changed |
| `ui-components` | a DevHubUI component was added or its signature changed |
| `panel-window` | `AppWindows`, `WindowLayout`, the status item, hints or the hot key changed |
| `xcode-toolchain` | a build, simctl, log or attach command or trap was learned |
| `extensions` | the config schema pieces or placements changed |
| `build-and-run` | a script, a build setting or a `DEVHUB_*` switch changed |

Check every type, file and command name you write with `grep` in `Packages/DevHubKit/Sources`. A skill keeps valid
YAML front matter (`name`, `description`); update the description when the content changed.

## 8. Check and commit

```sh
Scripts/build.sh
Scripts/test.sh
Scripts/smoke.sh
```

`layers: ok`, `anonymous: ok`, the app path, one passing test line and `alive`. Then commit locally:

```sh
git add -A
git commit
```

- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, with a plain English body and the
  attribution lines of the session.
- `Scripts/check-anonymous.sh` also reads the last commit message. Run it again after the commit; when it fails,
  amend the message with sample words only.
- Push `main` to `origin` after the commit, when `Scripts/check-anonymous.sh` prints `anonymous: ok`. Never force-push. The remote is public (STATUS decision 1).
- A failing check blocks the commit until it is fixed.

## Done when

- `git diff HEAD~1 -- CHANGELOG.md` shows the new lines.
- `docs/STATUS.md` has today's date.
- `docs/DEPENDENCIES.md`, `Scripts/allowed-tools.txt` and `Scripts/allowed-hosts.txt` when the session added or changed an executable, a host, a GitHub Action or a version (`.claude/rules/dependencies.md`).
- The step log has a row for every commit before the last one.
- Nothing in `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/extensions.md`, `docs/features/` or the skills contradicts
  the code.
