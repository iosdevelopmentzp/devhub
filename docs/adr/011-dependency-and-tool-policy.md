# ADR 011. Dependency and tool policy

Date: 2026-11-07. Status: accepted.

## Context

The owner asked for a review of every third-party library and tool, with one goal: no data leaves the Mac for a service the owner did not choose. The review found no library at all, two network calls that DevHub makes itself (the usage of Claude and Copilot, with the user's own token), about thirty executables that DevHub starts, one GitHub Action pinned to a tag, and no written rule about adding or updating any of them.

## Decisions

### D1. Consent and a risk analysis before any new dependency

`.claude/rules/dependencies.md` is the rule: a package, a vendored copy, an executable that DevHub or a repository script starts, a GitHub Action, a host, or a version change of any of them needs the owner's explicit "yes" in the session, and the question comes with a risk analysis (what it is, why, what it sends where and how to turn that off, how it is pinned, whether the source can be copied into the repository). A copy in `Packages/Vendor/<name>/` is the first choice for a library.

### D2. Allowlists checked by the build

`Scripts/check-dependencies.sh` runs in `Scripts/build.sh` and CI. It fails on a `.package(` in `Package.swift`, a remote package in the Xcode project, a package manager file, a GitHub Action without a 40-character commit SHA, an executable named in the Swift sources that is not in `Scripts/allowed-tools.txt`, or a host in `DevHubData` that is not in `Scripts/allowed-hosts.txt`. The inventory with what each tool sends where is `docs/DEPENDENCIES.md`.

### D3. Telemetry off for every child process

`TelemetryOptOutPolicy` (Domain) holds the environment variables that turn off the telemetry and update checks of the tools DevHub starts; `ShellRunner` sets them for every child process, and an explicit `extra` environment of a call still wins. `glab` has no variable; its check is turned off once in its config. Copilot CLI documents no opt-out.

### D4. The usage calls can be off

`UsageProviders.none` ("Off" in Settings → AI usage) stops the only network calls DevHub makes itself: no token is read and neither api.anthropic.com nor api.github.com is called. The default stays "Claude and Copilot".

## Consequences

- `actions/checkout` is pinned to `11d5960a326750d5838078e36cf38b85af677262` (v4.4.0). An update is a reviewed change.
- A new tool in the code without a line in `Scripts/allowed-tools.txt` breaks the build. That is intended.
- The variables disable the auto-update of `claude` for the one-shot runs DevHub starts; sessions in the terminal are not affected.

## Step log

| Commit | What |
|---|---|
| `27d9fd9` | D1 to D4: the rule, `check-dependencies.sh` with the allowlists in `build.sh` and CI, `docs/DEPENDENCIES.md`, `TelemetryOptOutPolicy` in `ShellRunner`, `UsageProviders.none`, `actions/checkout` pinned. |
