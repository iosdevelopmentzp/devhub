# ADR 005: Window mode, ports from the main DevHub, and daily tools

- **Status**: in progress, started 2026-10-27.
- **Scope**: `Packages/DevHubKit` (Shell, Settings, Home, Git, Pull Requests, Simulators, Build, AI, Palette), `DevHub.xcodeproj`, docs.

## Context

The main DevHub got new features after this repository was ported from it (its commits from 2026-10-19 to 2026-10-21): branch pins, labels and notes; Keep Mac awake; favorite AI sessions; drag to reorder favorite simulators; a fix for the Claude usage `limits` list; and a normal window instead of the menu bar panel.

The owner also asked for more comfort when working from any project: an easier project setup, faster project switching, better window handling and more pull request work inside DevHub.

## Decisions

1. **Two window modes.** Settings → General gets a "Window" picker with two values: "Menu bar panel" (the default, the current behaviour) and "Normal window". In window mode DevHub has one main window with a title bar, a Dock icon and a main menu. The close button and ⌘W hide the window, the menu bar icon and the global shortcut show it on the current desktop. This changes STATUS decision 2: the panel stays, but it is no longer the only mode.
2. **Right-click menu on the menu bar icon** in both modes: Show DevHub, the project list, Keep Mac awake, Settings…, Quit DevHub.
3. **Ports from the main DevHub** are checked against this repository's rules before they land. Nothing project-specific comes with them.
4. **Pull request comments.** A top-level comment on a request (both hosts), "Request Changes" with a message (GitHub only, GitLab has no such review state in `glab`), and a new thread on a diff line (both hosts).
5. **Checks and pipeline jobs** of a request show inside the details: the job list, the end of a failed job log, retry of one job.
6. **Project setup.** "Create .devhub Starter" writes a `project.json` with the values DevHub detected (remote, host kind, base branch, scheme, bundle ID). The example folder stays for a full reference.
7. **Project switching** from the ⌘K palette and with ⌃⌘1 to ⌃⌘9 (the order of Settings → Projects).
8. **Home "Today" card**: requests that wait for your review, your requests with failed checks, finished worktrees, booted simulators. A click opens the place.
9. **Simulator QA settings** per simulator: appearance, language and locale, text size, status bar override, location, privacy permissions, screenshot and video.
10. **Build log viewer**: after a build, errors and warnings as a list; a click opens `file:line` in the editor.

## Plan

- [x] P1. Claude usage: read the per-model weekly limits from the `limits` list.
- [ ] P2. Keep Mac awake: a Home card, a palette command, a cup on the menu bar icon.
- [ ] P3. Favorite AI sessions.
- [ ] P4. Drag to reorder favorite simulators.
- [ ] P5. Pin, label and add a note to local branches.
- [ ] W1. Window mode setting and the main window.
- [ ] W2. Right-click menu on the menu bar icon.
- [ ] R1. Top-level comment and Request Changes.
- [ ] R2. New thread on a diff line.
- [ ] R3. Checks and pipeline jobs in the details.
- [ ] S1. Create .devhub Starter.
- [ ] S2. Switch project from the palette and with ⌃⌘1 to ⌃⌘9.
- [ ] H1. Home "Today" card.
- [ ] Q1. Simulator QA settings.
- [ ] B1. Build log viewer.

## Step log

| Commit | Step | What it did |
|---|---|---|
