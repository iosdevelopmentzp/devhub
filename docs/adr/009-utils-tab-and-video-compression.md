# ADR 009. Utils tab and video compression

Date: 2026-11-02. Status: accepted, in progress (see the plan and the step log).

## Context

The owner records the Mac screen (Shift-Command-5 or QuickTime) and wants a smaller file to share. The wish (2026-11-02): a new tab "Utils" with sub-tabs; the first sub-tab compresses a video that the user drops on it, with quality choices that are easy to understand. The file must get much smaller and still look good. When a tool is missing, DevHub must show it, say how to install it, and start the install.

Facts checked on this Mac (2026-11-02):

- A screen recording of macOS is H.264 at the full Retina size (3456 × 2234 on a 16-inch MacBook Pro), with a variable frame rate up to 120 fps.
- `AVAssetExportSession` (used for simulator recordings, ADR 008 D3) has fixed presets and no quality factor. x264 with a constant rate factor (CRF) keeps text sharp at a much smaller size, so DevHub uses ffmpeg.
- Homebrew `ffmpeg` 9.0.2 has `libx264`, `libx265` and `ffprobe`. `brew install ffmpeg` installs 14 formulas in about a minute and prints one `==> ` line per step. It needs no password.
- A 5-second screen recording of 2.0 MB became 0.99 MB (CRF 20, full size), 0.26 MB (CRF 24, 1920) and 0.10 MB (CRF 28, 1280).
- `-fpsmax` works only with a constant frame rate output. ffmpeg then repeats frames of a variable frame rate source; x264 stores a repeated frame in a few bytes.
- ffmpeg turns a video with a rotation in its display matrix before the filters run, so the scale size uses the turned sides. `ffprobe` gives the rotation in `side_data_list[].rotation`.
- The panel closes on any click outside it, so a file cannot be dragged from Finder into the panel. A drop on the menu bar icon can reach DevHub.
- The installer of Homebrew needs an administrator password, so DevHub does not run it. The `.pkg` installer is on the releases page of the Homebrew repository on GitHub.

## Decisions

### D1. The Utils tab

1. `FeatureID.utils`, after AI (⌘9), title "Utils". No search field.
2. A segmented control under the run area selects the sub-tab (`UtilityID`). The choice is saved. The first sub-tab is "Compress Video". Later tools are new `UtilityID` cases.

### D2. The engine: ffmpeg

1. Port `VideoCompressionRepository`: `engineStatus`, `installEngine(onStep:)`, `info(of:)`, `compress(_:info:settings:onProgress:)`. Live: `FFmpegVideoCompressionRepository` in `DevHubData/Video/`, through `ShellRunner`, so every command is in the Output panel.
2. Status: ready (version and path), incomplete (ffmpeg without `ffprobe` or without `libx264`), or missing (with or without Homebrew).
3. Install: `brew install ffmpeg` with `HOMEBREW_NO_ENV_HINTS=1`. The `==> ` lines are the steps shown in the panel. A failure shows the `Error:` line of brew. Without Homebrew, DevHub shows the command, a link to the Homebrew installer and "Check Again".
4. ffmpeg is also a row in Settings → Doctor.

### D3. Quality

| Quality | Long side | Frame rate | x264 CRF | Sound |
|---|---|---|---|---|
| High | the source size | up to 60 | 20 | AAC 160k |
| Balanced (default) | up to 1920 | up to 30 | 24 | AAC 128k |
| Small | up to 1280 | up to 30 | 28 | AAC 96k |

Every quality: `-preset medium`, `-pix_fmt yuv420p`, `-movflags +faststart`, MP4. Sides are even numbers and never bigger than the source. "Keep sound" is a switch (`-an` when off). The quality and the switch are saved.

### D4. Files

1. The result goes next to the source: `<name> compressed.mp4`, then `<name> compressed 2.mp4`. The source stays.
2. ffmpeg writes into a hidden file `.<name> compressed-<token>.mp4` in the same folder. DevHub renames it at the end and deletes it after a failure or Stop.
3. A result bigger than the source is kept and marked.

### D5. The screen

1. A card for the engine: the state, the version and path, Install with the current step, the command to copy.
2. A drop zone that takes several files, and "Choose Videos…". Files that are not videos get a message.
3. A queue: one ffmpeg at a time. Each row shows the source facts (size, length, frame rate, file size), then progress with the time left and the speed, then the result (new size, saving, time). Stop, Remove, Reveal in Finder, Open, drag the result out. Jobs that wait for ffmpeg start after the install.
4. A notification when a video is done or failed while the panel is closed.

### D6. Drop on the menu bar icon

A video dropped on the menu bar icon opens the panel on Utils → Compress Video and starts. This is the way to compress from Finder while the panel is closed.

## Plan

1. Domain and Data: models, port, policy, ffmpeg repository, parsers, mock, spy, Doctor row, tests.
2. The Utils tab and the Compress Video screen: store, views, notifications.
3. Drop on the menu bar icon.

## Known limits

- An HDR video (10-bit HEVC from an iPhone) becomes 8-bit SDR without tone mapping, so its colours look flat.
- Only ffmpeg from Homebrew is installed by DevHub. Another ffmpeg on the PATH is used when it has `libx264` and `ffprobe`.

## Step log

| Commit | What it did |
|---|---|
| `f7dddb1` | Step 1: `VideoCompressionRepository`, `FFmpegVideoCompressionRepository` in `DevHubData/Video/` (ffprobe, ffmpeg with x264, `brew install ffmpeg`), `VideoCompressionPolicy`, parsers, mock, spy, the ffmpeg row in Doctor, `CommandKind` by the tool name of a full path, the ffmpeg integration suite. |
| `c747931` | Step 2: the Utils tab (`FeatureID.utils`, `UtilityID`, `UtilsStore`), `VideoCompressionStore` with the queue, Stop and the install of ffmpeg, `VideoEngineMapper`, `VideoJobRowMapper`, the views, the `utilities` notification kind and target, `FolderPicker.chooseFiles`, `WorkspaceActions.revealInFinder`. |
| `b605964` | Step 3: `FileDropView` (DevHubUI) over the status item button: a drop of videos calls `AppActions.compressVideos`, clicks go to `statusItemClicked`; the drop zone names the icon. |
