# Utils tab

The Utils tab holds small tools that do not belong to a project. A segmented control at the top chooses the tool; the choice is saved (`utils.selection`). The plan and the decisions are in ADR 009.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Utils/`, `DevHubData/Video/`, `DevHubDomain/Policies/VideoCompressionPolicy.swift`, `DevHubDomain/Repositories/VideoCompressionRepository.swift`.

| Tool | What it does |
|---|---|
| Compress Video | makes a screen recording or any video much smaller with ffmpeg, next to the original |

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

3. **The drop zone.** Drop one or more videos anywhere on the tab, or press **Choose Videos…**. The zone takes the free height while the list is empty, then shrinks to one line. A file that is not a `.mov`, `.mp4`, `.m4v`, `.mkv`, `.webm` or `.avi` gets a toast and an activity line.

4. **The list** of videos, in the order they were added. One video runs at a time.

   | State | Row |
   |---|---|
   | waiting | "Waiting in the queue", or "Waiting for ffmpeg. Install it above." in orange. The video starts by itself after the install |
   | reading | "Reading the video…" (`ffprobe`) |
   | compressing | a bar, "Compressing 42 % · 12.0 s left · 4.2× speed". The facts line shows the size, frame rate, length and file size of the source |
   | done | "86.4 MB → 9.6 MB, 89 % smaller · 18.0 s" in green, or "… % larger" in orange, and the file name as a link that shows it in Finder |
   | failed | the reason in red, for example "Cannot read clip.mov: Invalid data found when processing input" |
   | stopped | "Stopped. No file was written." |

   The header search filters the list by file name. **Clear Finished** removes the done, failed and stopped rows; the files stay.

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
- The menu bar panel closes when you click in Finder, so a file cannot be dragged from Finder into the panel. Pin the panel, use the window mode, or press **Choose Videos…**.
