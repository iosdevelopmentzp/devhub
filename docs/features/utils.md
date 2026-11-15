# Utils tab

The Utils tab holds the tools that do not belong to a project, the custom tabs of the `.devhub` folders, and every built-in tab the user moved out of the tab bar. A row of sub-tab buttons at the top chooses one; the choice is saved (`utils.selection`). The plan and the decisions of the tools are in ADR 009.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Utils/`, `Shell/TabLayout.swift`, `Shell/TabPlacementMenu.swift`, `Shared/Navigator.swift`, `DevHubData/Video/`, `DevHubDomain/Policies/VideoCompressionPolicy.swift`, `DevHubDomain/Repositories/VideoCompressionRepository.swift`.

| Tool | What it does |
|---|---|
| Compress Video | makes a screen recording or any video much smaller with ffmpeg, next to the original |
| Tickets | the Jira tickets of the project through `jira-cli`: mine, sprint, reported, watching or the whole project; group, sort and filter; details with comments; Start, Move to, Assign to Me, Add Comment, the branch name, the link (ADR 016) |
| a custom tab | the sections of a `.devhub/tabs/<id>.json` file ([Custom tabs](custom-tabs.md)) |
| a moved built-in tab | the same screen as in the tab bar, for example Logs or Network |

## Tab layout

- The tab bar holds Home, the built-in tabs, Utils, then the tabs placed in the bar. Utils holds the sub-tabs in the order: moved built-in tabs, the tools, custom tabs. That is the default order; the user can change it.
- **Drag a tab** in the tab bar or a sub-tab in Utils to change the order. The tab takes the place of the tab it is dragged over, at once. Every tab of the bar can be dragged, Home and Utils too. Dropping a movable tab on a tab of the other bar moves it there, before that tab; Home and Utils stay in the bar. A tab added later (a new custom tab) goes to the end of its bar. **Reset Tab Order** in the context menu of a tab goes back to the default order; it shows only when the order was changed. A right-click move into the other bar after a reorder puts the tab at the end there.
- Right-click a tab button in the tab bar: **Move to Utils**. Right-click a sub-tab button in Utils: **Show in Tab Bar**. The moved tab stays on screen in its new place. Home and Utils do not move. The hint of a button names the action.
- The choice is saved for the user, for every project, under `tabs.layout` (`tab.<id>` to `bar` or `utils`) and the order under `tabs.order` (the raw ids, both bars in one list). It wins over the `placement` field of a custom tab file. A custom tab without `placement` starts in Utils.
- ⌘1 to ⌘9 follow the positions in the tab bar, so a move or a drag changes the numbers. Sub-tabs have no shortcut; the ⌘K palette lists every tab of both places and opens it where it is.
- A notification, a palette entry or a row action that opens a moved tab (for example "Open the Logs tab") opens Utils on that sub-tab. The search field and its saved text follow the shown sub-tab.
- `DEVHUB_TAB` takes a sub-tab too: `utility.compressVideo`, `tab.<id>`, or a built-in id. The Debug build opens Utils on it when the layout puts it there.

## Tickets

Source: `Features/Utils/Tickets/`, `DevHubData/Jira/`, `DevHubDomain/Models/Tracker/`, `Policies/TrackerSettingsPolicy.swift`, `TrackerQueryPolicy.swift`, `TrackerBranchPolicy.swift`, `Repositories/IssueTrackerRepository.swift`. The plan and the decisions are in ADR 016.

The tab reads Jira through the `jira` tool of `jira-cli`, with the user's own login. `jira` reads the token from `JIRA_API_TOKEN`, then `~/.netrc`, then the keychain item `jira-cli` whose account is the `login` of `~/.config/.jira/.config.yml` (checked in the source of 1.7.0). A menu bar app does not inherit the shell, so when `jira` fails to log in, DevHub reads `JIRA_API_TOKEN`, `JIRA_AUTH_TYPE` and `JIRA_CONFIG_FILE` from a login `zsh` that sources `~/.zshrc` (its output goes to `/dev/null`, 10 s at most, the output of that read is never recorded) and runs `jira` again with them. After one success it passes them to every `jira` call of the app run. The values live only for one call and are never stored. A personal access token on Jira Server or Data Center needs `auth_type: bearer` in the config or `JIRA_AUTH_TYPE=bearer`. Set-up once: `brew install jira-cli`, a token, `jira init`, and the token in one of the three places (`security add-generic-password -s jira-cli -a <login> -w` asks for it, so it does not stay in the shell history).

1. **Which project.** `tracker` in `project.json` ([extensions.md §2](../extensions.md#2-projectjson)): `kind`, `project`, `statuses`, `startStatus`, `filter`, `branchFormat`. Without `tracker.kind`, a `git.ticketURL` that points at Jira turns the tab on. A project without a tracker shows "No tracker for this project" with the config line to add.

2. **The toolbar.** A scope picker, each scope inside the project of `tracker.project` or of the `jira` config, 50 tickets at most:

   | Scope | JQL before the status clause |
   |---|---|
   | Mine | `assignee = currentUser()` |
   | Sprint | `sprint in openSprints()` |
   | Reported | `reporter = currentUser()` |
   | Watching | `watcher = currentUser()` |
   | Project | none |

   Then the count, the view menu and Refresh. The status clause is `statusCategory != Done`, or `(statusCategory != Done OR updated >= -14d)` with "Done in the last 14 days" on. The view menu: **Group by** Status (In progress, To do, Other, Done), Type (most tickets first), Assignee (by name, Unassigned last) or Priority (Highest to Lowest, other names, then No priority); **Sort by** Last updated, Newest or Priority (`--order-by updated|created|priority`); the done toggle; **Types** with a check per type of the loaded tickets; Reset View. Its icon is filled and blue while a filter is on. Scope, order, done toggle, grouping and hidden types are saved (`utils.tickets.scope`, `.order`, `.includesDone`, `.grouping`, `.hiddenTypes`). The search field of the tab filters by key, summary, status, assignee and type. When the type filter hides every ticket, the list says so and offers Show All Types.

3. **The tool card.** Each time the panel opens on the tab, DevHub looks for `jira`, its config file (`~/.config/.jira/.config.yml`) and the login (`jira me`).

   | State | Card |
   |---|---|
   | ready | green, compact: `jira 1.7.0` and the login |
   | missing | orange "jira is not installed", `brew install jira-cli` to copy, Check Again |
   | no config file | orange "jira is not set up", `jira init` to copy, the bearer hint for a personal access token, Check Again |
   | no token, or the server did not take it | orange "jira cannot log in": the three token places, the `~/.zshrc` read, `auth_type: bearer`, and `security add-generic-password -s jira-cli -a <login of the jira config> -w` to copy, Check Again |
   | another failure | red "jira failed" with the message, Check Again |

4. **The list.** A row: a chevron, the type icon (bug red, story green, epic purple, task blue, other grey), the key (click to copy), the summary, the status tag (grey to do, blue in progress, green done), the priority tag (red highest, orange high, grey low), the assignee and "updated 2 hr. ago". On hover: **Start** (`jira issue move <key> <startStatus>`, hidden when the ticket is already there or done), **Copy Branch Name** (`tracker.branchFormat`, for example `feature/ABC-123-login-button-stays-disabled`), **Open in Browser**. The context menu: Show Details, Open in Browser, Copy Key, **Copy Key and Summary** (`ABC-123 Login button stays disabled`), Copy Branch Name, **Assign to Me** (not in Mine), Start and **Move to** with every status of `tracker.statuses` except the current one. A move or an assign shows a spinner in the row, logs ("Moved ABC-123 to In Review", "Assigned ABC-123 to you") with the command, toasts, and reads the list again; a failure logs and toasts the reason.

5. **Details.** A click on a row opens its details under it (`jira issue view <key> --raw`), a second click closes them. They show the description (8 lines, then Show all), "Reported by", "created", the labels and components, the parent and the sub-tasks with their status, and the last 5 comments with author and time; older comments link to the browser. A Jira Server answer has plain text; a Cloud answer has a document that DevHub turns into text (paragraphs, lists with •, mentions, links, emoji). Buttons: **Add Comment** opens a field (⌘↩ sends, Esc cancels; `jira issue comment add --no-input -- <key> <text>`, then the details are read again), **Assign to Me** (`jira issue assign <key> <login from jira me>`), **Open in Browser**. The details stay cached until the project or the config changes, and each opening reads them again in the background.

6. **Commands.** `jira version`, `jira me`, `jira issue list -q <jql> --raw --paginate 0:50 --order-by <field> [-p <project>]`, `jira issue view <key> --raw` (reads), `jira issue move`, `jira issue assign`, `jira issue comment add` (actions), and the login `zsh -lc …` read (a secret command: its output is not recorded). All in the Output panel.

7. **Limits.** Checked by tests, the mock ports and a headless snapshot (`DEVHUB_TICKET=ABC-123`); the new scopes, the details and the assign were not run against a live Jira in the session that built them. Sprint needs Jira Software; without it the JQL fails and the list shows the message. The list is one page of 50. Jira statuses are matched by name, as `jira issue move` takes them. A summary without ASCII letters gives a branch name of the key alone. The `~/.zshrc` read covers `zsh` only, and a `.zshrc` that stops early for a non-interactive shell gives no variables. The ticket chip of the Git tab still shows only the key.

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
