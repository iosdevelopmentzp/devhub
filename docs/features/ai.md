# AI tab

The AI tab lists the sessions of two command line AI tools: Claude Code (`claude`) and GitHub Copilot CLI (`copilot`). A session can be resumed in a terminal. The usage strip at the top of the panel shows how much of the plan limits is used.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/AI/`, `Features/Usage/`, `DevHubData/Claude/`, `DevHubData/Copilot/`, `DevHubData/AI/CompositeAISessionRepository.swift`.

## What it shows

### Session list

1. **The toolbar:** the number of sessions, the provider filter (Copilot, Claude, Both), the scope (This project, All), the "New" menu (a new Claude Code or Copilot CLI session in the project folder) and a refresh button.
2. **The list.** Favorite sessions come first, in a "Favorites" section with a yellow star and a count. The other sessions are grouped by day: "Today", "Yesterday", then the weekday and date. The newest session is first.

Each row shows:

1. an icon for the provider (orange when the folder exists, gray when it is missing), with a small yellow star when the session is a favorite;
2. the title;
3. the date and time of the last change, and the folder of the session (click to copy);
4. a provider tag (`Claude` or `Copilot`), the git branch tag (click to copy), and a red `folder missing` tag when the folder no longer exists;
5. the last prompt, when it differs from the title.

The header search filters by title, folder, branch, last prompt and provider name.

**This project** shows sessions whose folder is the project folder, a worktree of the project, or a folder inside one of them. A worktree folder next to the project folder counts too. A favorite session shows in every scope. **All** shows every session.

### Where the sessions come from

| Provider | Folder | What DevHub reads |
|---|---|---|
| Claude Code | `~/.claude/projects/*/<uuid>.jsonl` | The first `cwd` and `gitBranch`, the title (`custom-title`, else `ai-title`, else the last prompt) and the last prompt. A file without a `cwd` or a title is skipped |
| Copilot CLI | `~/.copilot/session-state/<id>/` | `workspace.yaml` and `events.jsonl`. The time is the newer change time of the two files |

DevHub keeps the parsed sessions in memory. On the next read it parses only the files that changed.

### Usage strip

The usage strip sits above the panel header, on every tab. It is on by default. Settings → "AI usage" can hide it, or limit it to Claude or to Copilot. DevHub reads the usage of the chosen providers only.

1. The strip shows one line per provider with its meters.
2. A click opens the details: the plan tag, "Updated <time>", and per meter the title, the reset time ("Resets in 2 h", or the weekday and time) and the used percent.
3. A meter is orange from 60 % and red from 85 %.
4. A Copilot plan without a premium request limit shows "No premium request limit".
5. An error shows in orange under the provider.

The Claude line is always there. The Copilot line appears only when DevHub found a Copilot token or got an error.

## Actions

### Session rows

| Action | What it does | Command |
|---|---|---|
| Star | Adds the session to the favorites or removes it. The star shows on hover, and always on a favorite | none |
| Resume | Opens the terminal of Settings in the session folder and resumes the session. Off when the folder is missing | `claude --resume <id>` or `copilot --resume <id>` |
| Copy resume command | Copies the command with the folder | `cd '<folder>' && claude --resume <id>` (or `copilot`) |
| Copy session ID | Copies the ID | none |
| Show folder in Finder | Opens the folder. Off when the folder is missing | none |
| New → Claude Code in `<project>`, Copilot CLI in `<project>` (toolbar) | Opens the terminal of Settings in the project folder and starts a new session. The session appears in the list after its first prompt. A worktree row has the same items under "Start AI Session Here", for the worktree folder, and the ⌘K palette lists "Start Claude Code in `<project>`" | `claude` or `copilot` |
| Refresh | Reads the sessions again | none |

How Resume and New open the terminal:

1. DevHub writes a temporary `run-<uuid>.command` file into `<temporary folder>/DevHub/`. The file removes itself, changes to the folder and runs the command in an interactive login shell (`$SHELL -i -l -c …`). The shell stays open after the command.
2. DevHub opens the file with the terminal app: `open -a <Terminal|iTerm2|Warp> <file>`, or `open -na Ghostty --args --working-directory=<folder> -e <file>`.

### Usage strip

| Action | What it does | Request |
|---|---|---|
| Strip click | Opens or closes the details | none |
| Refresh | Reads both providers again | see below |
| Retry | Shown on a provider with an error | see below |
| Open Usage | Opens the usage page of the provider in the browser | `https://claude.ai/settings/usage` or `https://github.com/settings/copilot` |

DevHub reads the usage every 5 minutes, and when the panel opens and the last read is older than 1 minute.

**Claude usage** (`AnthropicUsageRepository`):

1. DevHub reads the Claude Code login from the keychain: `security find-generic-password -s "Claude Code-credentials" -w`. When that fails, it reads `~/.claude/.credentials.json`.
2. An expired token shows an error. DevHub does not refresh the token.
3. DevHub sends `GET https://api.anthropic.com/api/oauth/usage` with the token as a bearer token and the header `anthropic-beta: oauth-2025-04-20`. The timeout is 15 seconds.
4. The plan comes from the `subscriptionType` of the login.

**Copilot usage** (`GitHubCopilotUsageRepository`):

1. When `gh` is installed, DevHub runs `gh auth token`.
2. Otherwise, or when that gives no token, DevHub runs `security find-generic-password -s copilot-cli -w`. This read stops after 10 seconds. After a stop, DevHub does not try the keychain again until the app restarts.
3. Without a token, the Copilot line is hidden.
4. DevHub sends `GET https://api.github.com/copilot_internal/user` with `Authorization: token <token>`. Status 401 or 403 shows that GitHub rejected the token.

The tokens are read for one request and then dropped. The Output panel shows the `security` and `gh auth token` commands, but not their output.

## Config

The AI tab reads no `.devhub` field.

The `ai.reviewCommand` field belongs to the Pull Requests tab ("Fix threads with AI"), not to this tab. See [extensions §2](../extensions.md#2-projectjson).

The terminal app comes from Settings → Tools → Terminal ([Settings](settings.md)).

## Saved preferences

| Key | Value | Written by |
|---|---|---|
| `claude.scope` | `This project` or `All` | `AISessionsStore` |
| `ai.provider` | `copilot`, `claude` or `both` | `AISessionsStore` |
| `ai.favorites` | The IDs of the favorite sessions | `AISessionsStore` |
| `app.settings` → `showUsageStrip` | Shows the usage strip | `SettingsStore` |
| `app.settings` → `showUsageInMenuBar` | Shows the session usage next to the menu bar icon | `SettingsStore` |

## Limits

1. DevHub does not check that `claude` or `copilot` is installed before Resume. The terminal uses the PATH of your login shell. The Doctor section of Settings shows missing tools.
2. The first read can take several seconds when `~/.claude/projects` and `~/.copilot/session-state` hold about 1 GB. Later reads use the cache.
3. The session list is read-only. DevHub does not delete, rename or start sessions.
4. The scope "This project" compares folders by path. It knows only the worktrees that exist now. A session in a worktree that was removed appears only under All.
5. The usage strip needs a Claude Code login on this Mac. An expired token shows an error until Claude Code refreshes it.
6. macOS can ask to allow `/usr/bin/security` to read the `copilot-cli` keychain item.
7. Resume was checked by tests only: a headless snapshot cannot click a button.
