# Dependencies and tools

Last reviewed: 2026-11-07 (ADR 011). The rule for changes: `.claude/rules/dependencies.md`. The check: `Scripts/check-dependencies.sh`, run by `Scripts/build.sh` and CI (`dependencies: ok`).

## Libraries

None. `Package.swift` has only local targets, the Xcode project references only `Packages/DevHubKit`, and the repository has no `Package.resolved`, `Podfile`, `package.json`, `Brewfile` or lock file. The check fails when one appears.

If a library is ever needed, the owner decides, and the first choice is a copy of its source in `Packages/Vendor/<name>/` with `LICENSE` and `VERSION` (version, source URL, commit): no registry and no network at build time.

## Network calls that DevHub makes itself

| Call | When | What leaves the Mac | Off switch |
|---|---|---|---|
| `GET https://api.anthropic.com/api/oauth/usage` (`AnthropicUsageRepository`) | on panel open and every 5 minutes while it is open, when "Show usage for" includes Claude | the Claude Code OAuth token from the keychain item `Claude Code-credentials` or `~/.claude/.credentials.json`, in the `Authorization` header; nothing else | Settings → AI usage → Show usage for: Off or Copilot only |
| `GET https://api.github.com/copilot_internal/user` (`GitHubCopilotUsageRepository`) | the same, when the choice includes Copilot | the token from `gh auth token`, else from the keychain item `copilot-cli` | Settings → AI usage → Show usage for: Off or Claude only |
| The mock server (`LocalMockServer`, `HTTPForwarder`) | while a simulator app runs with the mock server on | listens on 127.0.0.1 only; forwards the requests of the app to the upstream of the project config and the launch profile, nothing else | Network tab: mode off |

A token is read for one request and dropped. The output of `security` and `gh auth token` is never recorded. Log lines and recorded requests pass `LogRedactor` and `NetworkRequestRedactor`. Links such as `claude.ai/settings/usage`, `github.com/settings/copilot` and the pages of the code host open in the browser with `open`; DevHub sends nothing to them.

## Executables that DevHub starts

Every process goes through `ShellRunner`. It sets `TelemetryOptOutPolicy.environment` for the child: `DO_NOT_TRACK=1`, `HOMEBREW_NO_ANALYTICS=1`, `GH_TELEMETRY=false`, `GH_NO_UPDATE_NOTIFIER=1`, `CIRCLE_NO_TELEMETRY=1`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`. A tool is found on `PATH` plus `/opt/homebrew/bin`, `/usr/local/bin` and `~/.local/bin`. DevHub installs none of them, except `ffmpeg` from the button in Utils. The version is the one the user installed (Settings → Doctor shows it); a tool the user installs cannot be pinned, so the table names the minimum DevHub checks.

| Executable | Comes from | Used for | Talks to | Telemetry and update checks | Status |
|---|---|---|---|---|---|
| `git` | Xcode command line tools | Git, worktrees, branches, stashes | the remotes of the repository, with the user's SSH or HTTPS login | none | in use before the policy |
| `xcodebuild`, `xcrun` (`simctl`, `devicectl`), `xcode-select`, `xed` | Xcode | Build & Run, simulators, devices, logs, schemes | Apple, only for the signing of a device build, with the Apple ID in Xcode | Apple's own | in use before the policy |
| `open`, `osascript`, `security`, `defaults`, `ditto`, `du`, `ps`, `pgrep`, `mdfind`, `grep`, `plutil`, `rm`, `sh`, `zsh` | macOS | open apps and links, Xcode attach, keychain reads, app data, folder sizes, disk cleanup, scripts | local only | none | in use before the policy |
| `python3` | Xcode command line tools | the example scripts in `docs/examples/devhub`, two repository scripts | local only | none | in use before the policy |
| `gh` | Homebrew, the user's install | GitHub pull requests, checks, notifications, the Copilot token | api.github.com, or the GitHub Enterprise host of the repository, with the user's login | both off through `GH_TELEMETRY=false` and `GH_NO_UPDATE_NOTIFIER=1` | in use before the policy |
| `glab` | Homebrew, the user's install | GitLab merge requests | the GitLab host of the repository, with the user's login | an update check once a day; no environment variable, turn it off once with `glab config set check_update false` | in use before the policy |
| `circleci` (1 or newer) | Homebrew, the user's install | CircleCI workflows, jobs, flaky tests | circleci.com, with the user's login | off through `CIRCLE_NO_TELEMETRY=1` | in use before the policy |
| `claude` | npm, the user's install | Write with AI, Explain, Fix with AI, AI sessions | api.anthropic.com, with the user's login; the prompt holds the diff, the build errors or the crash report the user asked about | Statsig, Sentry, auto-update and feature flags off through `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` for the runs DevHub starts; a session in the terminal uses the user's own shell environment | in use before the policy |
| `copilot` | npm, the user's install | the same with Copilot CLI | GitHub, with the user's login | no documented opt-out variable for Copilot CLI; the `gh` opt-out does not cover it; the Copilot settings on GitHub control the data use | in use before the policy; the owner may remove it |
| `code`, `cursor`, `zed` | the editors of the user | "Open in Editor" for the editor chosen in Settings | local | their own, outside DevHub | in use before the policy |
| `ffmpeg`, `ffprobe` | Homebrew | Utils → Compress Video | local only | none | in use before the policy |
| `brew` | Homebrew | only `brew install ffmpeg` from the button in Utils | formulae.brew.sh and GitHub, for the formula and the bottle | analytics off through `HOMEBREW_NO_ANALYTICS=1` | in use before the policy |

The scripts and commands of a `.devhub` folder run whatever the user wrote there. They are the user's own code, not a dependency of DevHub. Settings → Doctor prints install commands (`brew install …`, `npm install -g …`) as text and runs none of them.

## Repository tooling

| Tool | Used by | Talks to | Pinned |
|---|---|---|---|
| `actions/checkout` | `.github/workflows/ci.yml` | github.com, from the runner | commit SHA `11d5960a326750d5838078e36cf38b85af677262` (v4.4.0); the check fails on a tag or a branch |
| GitHub-hosted runner `macos-26` | `ci.yml` | GitHub; the image brings Xcode, git and gh | by GitHub; the CI steps start no network tool |
| `python3`, `osascript` | `Scripts/ai/*.sh`, `Scripts/generate-example-config.sh`, `Scripts/auto-install.sh` | local only | the system versions |
| Claude Code hooks | `.claude/settings.json` | the two scripts in `Scripts/ai/` | — |

## Changing this list

Follow `.claude/rules/dependencies.md`: the risk analysis, the owner's "yes", the pin, a row here, the line in the allowlist. A row that the owner approved gets "approved <date>" in the Status column.
