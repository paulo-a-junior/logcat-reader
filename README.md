# logcat_reader

A desktop (Linux / macOS / Windows) Flutter app for reading Android `logcat`
output, either live from a device over adb or from a saved log file, with a
few everyday adb tools on the side.

## Features

- **Live capture** — streams `adb logcat -v threadtime` from a USB device or
  a TCP/IP device (`adb connect host:port` via the Wi-Fi button).
- **Offline viewing** — open a saved log file (`threadtime`, `time` and
  `brief` formats are parsed; any other line is shown verbatim).
  UTF-16 and UTF-32 files (e.g. `adb logcat > log.txt` in Windows
  PowerShell 5) are detected by BOM or byte pattern and converted in
  memory, with a warning; the file itself is not modified.
- **Two tables**, each with *Line*, *Process Name* and *Log Message* columns:
  - **Raw** (top) — every line.
  - **Filtered** (bottom) — only lines matching the enabled filters (empty
    when none is enabled), with a stripe in the matching filter's colour.
    Clicking a row scrolls the raw table to that line.
  - Select rows with a click, <kbd>Shift</kbd>+click (scroll in between to
    select far-apart lines) or click-and-drag (dragging past the top or
    bottom edge auto-scrolls). Hold <kbd>Ctrl</kbd> (<kbd>Cmd</kbd> on
    macOS) to build a non-contiguous selection: click toggles a single row,
    drag adds a range, and <kbd>Shift</kbd> extends from the last clicked
    row while keeping the rest. <kbd>Ctrl</kbd>+<kbd>A</kbd> selects all,
    <kbd>Esc</kbd> clears the selection.
  - Right-click a row to copy the raw line, the message, the process name or
    the whole row (tab-separated); with several rows selected it copies all
    of them. <kbd>Ctrl</kbd>+<kbd>C</kbd> copies the selected raw lines.
- **Save log** — the save button (or <kbd>Ctrl</kbd>+<kbd>S</kbd>) writes
  all lines, or only the filtered ones, as raw logcat text that can be
  reopened later.
- **Filter balloons** — saved filters appear as coloured balloons above the
  filtered table. Click a balloon to toggle it, double-click to edit it;
  right-click (or long-press) to edit, duplicate or delete it;
  **+ Add filter** creates a new one.
  - Each filter has a name, colour, mode (**Show** or **Hide**) and criteria:
    message text (plain or regex, optional case sensitivity), process name or
    PID, tag, and minimum level.
  - *Hide* filters always remove the lines they match; enabled *Show* filters
    combine as **Any** or **All**.
  - The **Manage filters** page (tune icon) lists every filter with
    drag-to-reorder, enable switches and a live editor.
  - Filters persist between runs. *Errors*, *Warnings* and *Crashes* are
    created (disabled) on first run.
- Tables follow new lines while scrolled to the bottom; scroll up to pause.
  Drag the divider to resize the two tables.
- **Auto-reconnect** — when the device drops (USB unplug, network loss,
  reboot) the app waits for it to return (re-running `adb connect` for
  network devices) and resumes logcat without duplicating lines. A marker
  line records the reconnect or reboot (detected via the kernel `boot_id`).
- **Notifications** — in-app pop-ups for connection lost, reconnected, and
  crashes seen in live logs (`FATAL EXCEPTION`, `ANR in`, native
  `Fatal signal`), with a *Show* action that jumps to the line. Crashes
  already in the buffer when logcat starts are not reported.

## Device tools

The navigation rail on the left switches between views; logcat keeps
streaming while another view is open. Device views act on the device selected
in the toolbar.

| View | What it does |
|------|--------------|
| **Logs** | The two log tables and filter balloons |
| **Apps** | Installed packages (user apps, optionally system apps) with search; launch, force stop, clear data, save APK, uninstall; *Install APK…* |
| **Files** | Browse the device file system (starts at `/sdcard`); double-click to open folders; pull files/folders, push files, new folder, delete |
| **Shell** | Runs one-shot `adb shell` commands with streamed output, ↑/↓ history, per-command stop and copy; also collects shortcut output |
| **Shortcuts** | Manage saved commands: add, edit, reorder, delete, run |

Toolbar extras:

- **Device actions** menu — install APK, take a screenshot (saved as PNG),
  reboot (normal / recovery / bootloader, with confirmation). With
  auto-reconnect on, logcat resumes once the device is back.
- **Shortcuts** — pinned shortcuts appear as icon buttons; the ⚡ menu lists
  all of them. A shortcut has a name, icon and command, and runs as
  `adb shell <command>`, `adb <arguments>`, or a command/script on this
  computer (with `ANDROID_SERIAL` and `ADB` set so scripts target the selected
  device). It can ask for confirmation first, and either notify when done or
  open the Shell view. Shortcuts persist between runs; *Home*, *Current
  activity* and *Device properties* are created on first run.

Destructive actions (uninstall, clear data, delete, reboot) always ask first.

## Preferences

Open with the gear button or <kbd>Ctrl</kbd>+<kbd>,</kbd>. Settings are
saved with `shared_preferences`.

| Setting | Options |
|---------|---------|
| adb executable | Path to `adb`, with a file picker and version check; empty (default) uses `$ADB`, then `adb` on `PATH` |
| Run adb as root | off (default) / on — runs `adb root` before reading device logs and again after a reboot, so logcat, `ps` and shell commands run as root. Only works on `userdebug`/`eng` builds; a failure is reported and logging continues as non-root. Toggling it while streaming restarts adbd (`adb root`/`adb unroot`) and resumes logcat. When off, adbd is left in its current mode on connect |
| Auto-reconnect | on (default) / off |
| Theme | System (default) / Light / Dark |
| Long lines | Ellipsis (default) / Wrap |
| Log font size | 8–24 (default 12.5) |
| Language | System default / English / Português |
| Notifications | Connection lost, Reconnected, App crashes (each on/off) |

Process names are resolved from the device's `ps -A` (refreshed when unknown
PIDs appear) and from ActivityManager `Start proc` lines, which also works for
offline files. Unresolved PIDs are shown as a bare number.

## Requirements

- Flutter 3.27+.
- `adb`: choose it in Preferences, put it on `PATH`, or set the `ADB`
  environment variable to its full path.
- macOS: the App Sandbox is disabled in `macos/Runner/*.entitlements` so the
  app can launch `adb`.

## Running

```sh
flutter run -d linux     # or: -d macos / -d windows
```

## Releases

Pushing a tag of the form `vA.B.C` (e.g. `v1.2.0`) runs
`.github/workflows/release.yml`, which builds release binaries on Linux,
Windows and macOS runners and publishes a GitHub release with:

- `logcat_reader-A.B.C-linux-x64.tar.gz` (built in an `ubuntu:20.04`
  container, so it runs on glibc 2.31+: Ubuntu 20.04, Debian 11 and newer;
  needs GTK 3)
- `logcat_reader-A.B.C-windows-x64.zip`
- `logcat_reader-A.B.C-macos.zip` (unsigned `.app`)
- `SHA256SUMS.txt`

The app version is taken from the tag (`--build-name A.B.C`), so
`pubspec.yaml` does not need to be bumped. Other tags (`v1.2`, `v1.2.3-rc1`)
are ignored.

```sh
git tag v1.2.0 && git push origin v1.2.0
```

## Layout

| Path | Purpose |
|------|---------|
| `lib/src/adb/adb_client.dart` | `adb` wrapper: devices, connect, `ps`, logcat, reboot, packages, files, screenshot |
| `lib/src/parsing/logcat_parser.dart` | Line parser for logcat output formats |
| `lib/src/models/` | `LogEntry`, `LogLevel`, `LogFilter`, `SavedFilter` |
| `lib/src/controller/log_controller.dart` | Log buffer, source lifecycle, reconnect, batching, filtering, crash detection |
| `lib/src/controller/log_events.dart` | Status and event types consumed by the UI |
| `lib/src/settings/app_settings.dart` | Persisted user preferences |
| `lib/src/settings/filter_store.dart` | Persisted saved filters and Any/All mode |
| `lib/src/ui/` | Home page (navigation rail), source toolbar, log table, preferences dialog |
| `lib/src/ui/filters/` | Balloon bar, filter editor/dialog, filter manager page, colour palette |
| `lib/src/adb/device_selection.dart` | Device list and selected device shared by all views |
| `lib/src/tools/shell_console.dart` | Runs adb/host commands and keeps the Shell view history |
| `lib/src/models/command_shortcut.dart`, `lib/src/settings/shortcut_store.dart` | Command shortcut model and persisted store |
| `lib/src/ui/tools/` | Apps, Files, Shell and Shortcuts views, device menu, shortcut bar/editor/runner |
| `lib/l10n/*.arb` | Translations; `lib/l10n/gen/` is generated by `flutter gen-l10n` |

## Adding a language

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb` and translate it.
2. Add `<code>` to `AppSettings.supportedLanguages` and its name to
   `LocalizedStrings.languageName`.
3. Run `flutter gen-l10n` (also runs automatically on build).
