# Dependencies and tools

The owner decides what runs in this project. Nothing new goes in without the owner's explicit "yes" in the session,
and the question comes with a risk analysis. The goal: no data leaves the Mac for a service the owner did not choose.

## What needs consent

- A Swift package, a vendored library, a Homebrew formula, an npm package, a Python module, a GitHub Action, a git
  hook, or any other third-party code.
- A new executable that DevHub starts (`ShellRunner`), that a repository script runs (`Scripts/`, `Scripts/ai/`,
  `.github/`), or that a doc tells the user to install.
- A version change of any of them: a GitHub Action SHA, a minimum tool version, a vendored copy.
- A new host that the app connects to itself (`URLSession`, `NWConnection`).

## How to ask

Write the risk analysis first and put it in the message that asks:

1. What it is: name, maintainer, licence, last release, size.
2. Why DevHub needs it, and what the alternative without it costs.
3. What it sends where: telemetry, update checks, crash reports, the data it handles. Name the switch that turns each
   one off, or say that there is none.
4. How it is pinned: the exact version or commit SHA, and how an update will be reviewed.
5. Whether the source can be copied into the repository instead. A copy is the first choice:
   `Packages/Vendor/<name>/` with `LICENSE` and `VERSION` (version, source URL, commit), no change to the copied code
   without a note in `VERSION`.

Then wait. "Later", "maybe" or no answer means no.

## After consent

- Pin it: a 40-character commit SHA for a GitHub Action (`owner/repo@<sha> # vX.Y.Z`), an exact version for a package,
  the version from the risk analysis for a tool.
- Record it in `docs/DEPENDENCIES.md` with the owner's decision and date.
- Add an executable to `Scripts/allowed-tools.txt`, a host to `Scripts/allowed-hosts.txt`.
  `Scripts/check-dependencies.sh` (run by `Scripts/build.sh` and CI) fails on anything else.
- Turn telemetry off where the tool has a switch: `TelemetryOptOutPolicy` (Domain) holds the environment variables
  that `ShellRunner` sets for every child process.

## Always

- No package registry in the build: `Package.swift` has no `.package(`, the Xcode project has no remote package, and
  the repository has no `Package.resolved`, `Podfile`, `package.json`, `Brewfile` or lock file.
- No network call from DevHub itself except to the hosts in `Scripts/allowed-hosts.txt`. Everything else goes through
  a CLI tool the owner approved, with the user's own login.
- Settings → Doctor may print an install command as text. DevHub runs an install only where the owner approved it
  (`brew install ffmpeg` on the button in Utils).
- The scripts and commands of a `.devhub` folder are the user's own code: they run whatever the user wrote. That is
  not a dependency of DevHub and needs no consent.
