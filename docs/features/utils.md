# Utils tab

The Utils tab holds the tools that do not belong to a project, the custom tabs of the `.devhub` folders, and every built-in tab the user moved out of the tab bar. A row of sub-tab buttons at the top chooses one; the choice is saved (`utils.selection`). The plan and the decisions of the tools are in ADR 009.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Utils/`, `Shell/TabLayout.swift`, `Shell/TabPlacementMenu.swift`, `Shared/Navigator.swift`, `DevHubData/Video/`, `DevHubDomain/Policies/VideoCompressionPolicy.swift`, `DevHubDomain/Repositories/VideoCompressionRepository.swift`.

| Tool | What it does |
|---|---|
| Compress Video | makes a screen recording or any video much smaller with ffmpeg, next to the original |
| Tickets | the open Jira tickets of the project through `jira-cli`: yours or the whole project, Start, Move to, the branch name, the link (ADR 015) |
| a custom tab | the sections of a `.devhub/tabs/<id>.json` file ([Custom tabs](custom-tabs.md)) |
| a moved built-in tab | the same screen as in the tab bar, for example Logs or Network |

## Tab layout

- The tab bar holds Home, the built-in tabs, Utils, then the tabs placed in the bar. Utils holds the sub-tabs in the order: moved built-in tabs, the tools, custom tabs.
- Right-click a tab button in the tab bar: **Move to Utils**. Right-click a sub-tab button in Utils: **Show in Tab Bar**. The moved tab stays on screen in its new place. Home and Utils do not move. The hint of a button names the action.
- The choice is saved for the user, for every project, under `tabs.layout` (`tab.<id>` to `bar` or `utils`). It wins over the `placement` field of a custom tab file. A custom tab without `placement` starts in Utils.
- ⌘1 to ⌘9 follow the positions in the tab bar, so a move changes the numbers of the tabs after it. Sub-tabs have no shortcut; the ⌘K palette lists every tab of both places and opens it where it is.
- A notification, a palette entry or a row action that opens a moved tab (for example "Open the Logs tab") opens Utils on that sub-tab. The search field and its saved text follow the shown sub-tab.
- `DEVHUB_TAB` takes a sub-tab too: `utility.compressVideo`, `tab.<id>`, or a built-in id. The Debug build opens Utils on it when the layout puts it there.

## Tickets

Source: `Features/Utils/Tickets/`, `DevHubData/Jira/`, `DevHubDomain/Models/Tracker/`, `Policies/TrackerSettingsPolicy.swift`, `TrackerQueryPolicy.swift`, `TrackerBranchPolicy.swift`, `Repositories/IssueTrackerRepository.swift`. The plan and the decisions are in ADR 015.

The tab reads Jira through the `jira` tool of `jira-cli`, with the user's own login. DevHub never reads the token: it lives in the keychain item `jira-cli` (account = the login), in `~/.netrc`, or in `JIRA_API_TOKEN` of the shell (a menu bar app does not see the shell, so use the keychain or `~/.netrc`). Set-up once: `brew install jira-cli`, an API token from the Atlassian account, `security add-generic-password -s jira-cli -a <login> -w <token>`, then `jira init`.

1. **Which project.** `tracker` in `project.json` ([extensions.md §2](../extensions.md#2-projectjson)): `kind`, `project`, `statuses`, `startStatus`, `filter`, `branchFormat`. Without `tracker.kind`, a `git.ticketURL` that points at Jira turns the tab on. A project without a tracker shows "No tracker for this project" with the config line to add.

2. **The toolbar.** A scope picker (**Mine**: `assignee = currentUser() AND statusCategory != Done`; **Project**: `statusCategory != Done`), both inside the project of `tracker.project` or of the `jira` config, newest update first, 50 at most. The count, and Refresh. The scope is saved (`utils.tickets.scope`). The search field of the tab filters by key, summary, status and assignee.

3. **The tool card.** Each time the panel opens on the tab, DevHub looks for `jira`, its config file (`~/.config/.jira/.config.yml`) and the login (`jira me`).

   | State | Card |
   |---|---|
   | ready | green, compact: `jira 1.7.0` and the login |
   | missing | orange "jira is not installed", `brew install jira-cli` to copy, Check Again |
   | no config file | orange "jira is not set up", `jira init` to copy, the keychain hint, Check Again |
   | no token | orange "jira has no API token", the `security add-generic-password …` command to copy, Check Again |
   | another failure | red "jira failed" with the message, Check Again |

4. **The list**, in sections by status category: In progress, To do, Other, Done. A row: the type icon (bug red, story green, epic purple, task blue, other grey), the key (click to copy), the summary, the status tag (grey to do, blue in progress, green done), the priority tag (red highest, orange high, grey low), the assignee and "updated 2 hr. ago". On hover: **Start** (`jira issue move <key> <startStatus>`, hidden when the ticket is already there or done), **Copy Branch Name** (`tracker.branchFormat`, for example `feature/ABC-123-login-button-stays-disabled`), **Open in Browser**. The context menu adds Copy Key and **Move to** with every status of `tracker.statuses` except the current one. A move shows a spinner in the row, logs "Moved ABC-123 to In Review" with the command, toasts, and reads the list again; a failure logs and toasts the reason.

5. **Commands.** `jira version`, `jira me`, `jira issue list -q <jql> --raw --paginate 0:50 --order-by updated [-p <project>]` (reads), `jira issue move <key> <status>` (an action). All in the Output panel.

6. **Limits.** Checked by tests and the mock ports; the live tool was not run with a token in the session that built the tab (ADR 015, step 5). The list is one page of 50. Jira statuses are matched by name, as `jira issue move` takes them. A summary without ASCII letters gives a branch name of the key alone. The ticket chip of the Git tab still shows only the key.

## Compress Video

### What it shows

1. **The ffmpeg card.** DevHub looks for `ffmpeg`, `ffprobe` and the `libx264` encoder each time the panel opens.

   | State | Card | Action |
   |---|---|---|
   | ready | green line "ffmpeg 9.0.2" and the path | none |
   | missing, Homebrew found | orange: "ffmpeg is not installed", the command `brew install ffmpeg` (click to copy) | **Install ffmpeg** runs `brew install ffmpeg` |
   | installing | a spinner and the current Homebrew step ("Pouring x264…") | none; every line is in the Output panel |
   | install failed | red: the `Error:` line of brew | **Try Again** |
   | missing, no Homebrew | orange: "ffmpeg and Homebrew are not installed" | **Get Homebrew** opens the releases page of Homebrew on GitHub (download the `.pkg` and open it), **Check Again** |
   | ffmpeg without `ffprobe` or `libx264` | orange, with `brew reinstall ffmpeg` to copy | **Check Again** |

2. **Quality** and **Keep sound**. Both are saved (`utils.video.settings`) and go with each video when it is added.

   | Quality | What the user reads | ffmpeg |
   |---|---|---|
   | High | The same size and up to 60 fps. The best detail; the file stays larger. | `-crf 20`, `-fpsmax 60`, AAC 160k |
   | Balanced (default) | Up to 1920 px and 30 fps. Sharp text and a much smaller file. Good for most recordings. | `-crf 24`, long side up to 1920, `-fpsmax 30`, AAC 128k |
   | Small | Up to 1280 px and 30 fps. The smallest file for a chat; small text can blur. | `-crf 28`, long side up to 1280, `-fpsmax 30`, AAC 96k |

   Keep sound off adds `-an`.

3. **The drop zone.** Drop one or more videos anywhere on the tab, or press **Choose Videos…**. The menu bar panel closes when you click in Finder, so the zone also says: "Panel closed? Drop videos on the DevHub icon in the menu bar." A video dragged over the icon highlights it; the drop opens the panel on this tool and starts the videos. Other files are not taken. The zone takes the free height while the list is empty, then shrinks to one line. A file that is not a `.mov`, `.mp4`, `.m4v`, `.mkv`, `.webm` or `.avi` gets a toast and an activity line.

4. **The list** of videos, in the order they were added. One video runs at a time.

   | State | Row |
   |---|---|
   | waiting | "Waiting in the queue", or "Waiting for ffmpeg. Install it above." in orange. The video starts by itself after the install |
   | reading | "Reading the video…" (`ffprobe`) |
   | compressing | a bar, "Compressing 42 % · 12.0 s left · 4.2× speed". The facts line shows the size, frame rate, length and file size of the source |
   | done | "86.4 MB → 9.6 MB, 89 % smaller · 18.0 s" in green, or "… % larger" in orange, and the file name as a link that shows it in Finder |
   | failed | the reason in red, for example "Cannot read clip.mov: Invalid data found when processing input" |
   | stopped | "Stopped. No file was written." |

   The search field in the toolbar filters the list by file name. **Clear Finished** removes the done, failed and stopped rows; the files stay.

### Actions

| Action | Where | What it does |
|---|---|---|
| Stop | hover, menu | stops ffmpeg (SIGTERM) or takes a waiting video out of the queue. The hidden partial file is deleted |
| Open the Result | hover, menu | opens the MP4 in its default app |
| Show the Result in Finder | hover, menu, the file name | selects the MP4 in Finder |
| Drag the row | a done row | drags the MP4 file, for example into a chat or a ticket |
| Show the Original in Finder | menu | selects the source |
| Compress Again | hover, menu | adds the same video again with the current quality |
| Remove from List | hover, menu | removes the row; the files stay |

### Commands

| Step | Command |
|---|---|
| check | `ffmpeg -hide_banner -version`, `ffmpeg -hide_banner -encoders` (reads, hidden in the Output panel unless "Show reads") |
| install | `brew install ffmpeg` with `HOMEBREW_NO_ENV_HINTS=1` |
| read | `ffprobe -v error -print_format json -show_format -show_streams <file>` |
| compress | `ffmpeg -hide_banner -nostdin -y -loglevel error -progress pipe:1 -stats_period 1 -i <file> -map 0:v:0 -map 0:a:0? -c:v libx264 -preset medium -crf 24 -pix_fmt yuv420p -fpsmax 30 -vf scale=<w>:<h> -c:a aac -b:a 128k -movflags +faststart -f mp4 <folder>/.<name> compressed-<token>.mp4` |

The tools run by the path DevHub found (`/opt/homebrew/bin/ffmpeg`), so the Output panel shows the full path.

### Files

- The result is `<name> compressed.mp4` in the folder of the original, then `<name> compressed 2.mp4`. The original stays.
- ffmpeg writes a hidden file first. DevHub renames it at the end, and deletes it after a failure or Stop.
- A turned video (an iPhone video with a rotation) is scaled by its shown sides, and the result has no rotation.

### Notifications

A finished or failed video posts "Video compressed: <name>" or "Could not compress <name>" while the panel is closed (kind "Utils: compressed videos" in Settings → Notifications). A click opens this tab.

### Limits

- An HDR video (10-bit HEVC) becomes 8-bit SDR without tone mapping, so its colours look flat.
- DevHub installs ffmpeg only with Homebrew. It never runs the Homebrew installer, which needs an administrator password.
