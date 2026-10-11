# Working on Worldscape

Read `docs/PRINCIPLES.md` before changing the product or customization model.
Preserve the three layers: an excellent opinionated default, a small set of
quick adjustments, and readable source users can freely reshape with their agents.
User requests may deliberately change these defaults or the whole composition.

## Where to work

- `BarWidget.qml`: bar content, date/time formats, popup loading and IPC.
- `Panel.qml`: calendar, world-clock/weather presentation and panel interactions.
- `Model.js`, `WeatherModel.js`, `StatusColors.js`: presentation helpers.
- `combined.py`: cached clock/weather snapshots and asynchronous refresh path.
- `weather.py`: forecast fetching, cache and optional location detection.
- `locations.json`, `local-location.json`: current location configuration.
- `docs/design-lab/index.html`: interactive appearance/customization prototype.

Keep prototype behavior and native behavior clearly distinguished in documentation.
Do not turn every prototype control into a shipped setting. Shared preferences
should survive design changes; use per-design settings only where they add value.
No agent service is required at runtime.

## Validate relevant changes

- Run `omarchy plugin validate .` after manifest/entry-point changes.
- Check Python syntax and the offline clock path after helper changes.
- Exercise changed gallery controls and both palettes for prototype changes.
- For native UI changes, verify actual loading, readable light/dark states,
  opening/closing, settings persistence, and behavior without fresh weather.
- Work in this repository. Installing into a live user plugin directory is a
  separate step; preserve a backup when that step is requested.

Avoid committing credentials, personal location caches, session data or backups.
Document limitations honestly and preserve upstream license attribution.
