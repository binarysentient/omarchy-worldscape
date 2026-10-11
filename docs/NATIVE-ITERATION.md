# Native iteration 1 · Windows on the world

First native QML implementation of the Opus design study
(`docs/design-studies/opus/`). Author: Claude Opus 5.5, as implementation owner.

## Architecture

| File | Role |
| --- | --- |
| `BarWidget.qml` | Bar label and formats (unchanged behaviour), popup host, IPC (adds `customize`). |
| `Panel.qml` | Preferences, Auto resolution, data processes, layout, keyboard. |
| `CalendarCard.qml` | Weekday headline, home mood card, month grid. |
| `CityCard.qml` | One window plus the information sill below it. |
| `CityWindow.qml` | The artwork: frame mask, still Canvas, animated overlays. |
| `Cloud.qml` | One drifting cloud. |
| `DayRibbon.qml` | 24-hour band with a marker per city. |
| `CustomizeView.qml`, `Choice.qml` | The Customize sheet and its option rows. |
| `Sky.js` | Colour mixing, solar times, sky keyframes, phases, weather kinds, city clock. |
| `Skylines.js` | Silhouette data per city and a tiny SVG-path tracer for Canvas. |
| `ThemeMatch.js` | Installed theme table, curated style picks, OKLab nearest match. |
| `combined.py` | Adds `utcOffsetMinutes` per row; tolerates blank/old snapshots. |

**Time.** The helper reports each city's real UTC offset from tzdata. The panel
keeps a minute-precision `nowMs` and derives each city's wall clock and sky from
it, so clocks keep moving between helper runs. Rows from older snapshots without
the offset fall back to inferring it from their `HH:MM` field.

**Sun.** Sunrise and sunset are computed locally (NOAA low-precision equations)
from the coordinates already in each row. No API change was needed and old weather
caches work unchanged. Sky keyframes are placed relative to those times.

**Weather.** Unchanged asynchronous architecture: `combined.py` (clock, cached,
no network) and `combined.py --weather` (fetch with 15-minute cache) run as
separate processes. A failed or empty clock read keeps the previous rows instead
of blanking the panel. Missing current weather is drawn as a muted, unknown sky.

**Theme.** `Color.background/foreground/accent` drive both the palette and Auto
matching, so theme switches (pushed through the shell's `applyTheme` IPC) rebind
everything. Scene colours (lamp warmth, ground green) come from the matched
theme's table entry. Interface light/dark comes from `Color.popups`; the scene's
daylight never depends on it.

**Performance.** Each window's still picture is one Canvas repainted only when a
`paintKey` changes (size, minute, weather, style, palette), about once a minute
per window while visible. Animation uses property animations on stable items:
cloud x-offset, a pre-drawn rain/snow sheet sliding vertically, star-layer opacity,
sun-glow scale, a lightning opacity sequence. All run only while the panel is open,
Motion is Animated and Customize is not showing. The arched frame is a
`MultiEffect` mask (same technique as the shell's image picker).

## Keyboard

| Where | Keys |
| --- | --- |
| Panel | **T**/Enter/Space today · **← →** (or h/l, ↑↓, j/k) month · **W** week start · **C** Customize · **Tab**/Shift+Tab switch shell panels · **Esc** close |
| Customize | **↑ ↓** row · **← →** option · **Enter**/Space apply · **Tab**/Shift+Tab next/previous row (wraps) · **C** or **Esc** back to the panel |

Customize uses an explicit cursor (`cursorRow`, `cursorCol` in
`CustomizeView.qml`). Row 0 is Reset/Done; the cursor starts on Window style,
on its current choice. The focused row is highlighted and the focused option gets
a 2 px ring; the shell `Button`s use their `hasCursor` state. `Panel.qml` scrolls
the focused row into view when the sheet overflows. Options carry `Accessible`
radio-button roles and names ("Motion: Quiet"). Option rows wrap onto further
lines at narrow widths, beside a fixed-width label that also wraps.

## Settings keys (shell.json entry)

`style` (auto|glass|woodblock|ink|neon), `motion` (animated|quiet), `clockLayout`
(expanded|compact), `calendar` (show|hide), `calendarLayout` (expanded|compact),
`hours` (24|12), `unit` (metric|imperial), `weekStartDay`, `format`, `barWeather`.
Missing keys mean the default.

## Checks and local review

Implementation: Claude Opus 5.5 at medium effort. Independent review:
GPT-6.1 Sol at medium effort. Codex handled command execution, local installation,
screenshots and integration verification. Claude's own command tools were unavailable;
checks below were run by Codex and Sol.

- All nine QML components compile Ready with the actual Wayland backend, including
  the keyboard fixes. Plugin manifest validation and Python syntax checks pass.
- Sol verified all 22 installed palette triples, finite skyline paths, solar/sky
  calculations over a year for the configured cities, and timezone/date rollover.
- Installed in the running shell, replacing the personal clock's bar slot while
  preserving location preferences. A backup of the previous plugin and shell.json
  was made outside the repository. One shell restart released cached QML dependencies.
- Actual native captures: Tokyo Night/Glass, Flexoki Light/Ink, Retro 82/Neon.
  Sol reviewed all three and found no clipping or blocking visual issue. The custom
  Thundermonkey Day palette also resolves and is retained. Woodblock and compact
  clocks with the calendar hidden were separately viewed in the live shell.
- Keyboard-only changes persisted to shell.json: style, Quiet, compact clocks,
  12-hour time, Fahrenheit, compact calendar, Monday week start, bar date format,
  and hidden bar weather. Keyboard access to Reset restored defaults. Settings
  were restored to the user's pre-test choices afterward.
- IPC open/Customize/close and Escape were exercised. Fresh runtime logs contain
  no Worldscape load/binding errors. Cached and empty-cache offline clock paths
  return four usable timezone-aware rows without a weather request.

Sol approved this first iteration for local user review after its keyboard finding
was fixed. The current local version has not been published. Broader small-screen,
multi-monitor, mixed-DPI and network-failure visual testing remain before a release.
This iteration is not marketplace-ready.

## Known gaps

- Exactly what `locations.json` lists; no in-panel city editor yet.
- Sunrise/sunset are computed, not taken from Open-Meteo; accurate to minutes.
- Generic `serif`/`sans-serif` families are used for Woodblock/Glass/Ink type,
  so the exact face depends on the system's fontconfig defaults.
- Canvas art is drawn at logical resolution; on fractional/HiDPI scales it may
  look softer than vector text.
- Palette pinning from the study is not shipped: the palette always follows
  the desktop; only the style can be overridden.
- Silhouettes are recognisable sketches, not accurate skylines.
