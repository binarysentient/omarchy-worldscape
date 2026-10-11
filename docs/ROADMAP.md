# Worldscape roadmap

Guided by [our design principles](PRINCIPLES.md): an excellent default, a small
menu of everyday choices, and source that users and their agents can reshape.

## Working baseline

- Native calendar, world clocks and cached weather from the existing widget.
- Standalone plugin identity and isolated weather cache.
- Interactive HTML studies for five illustrated designs in day/night palettes.
- Prototype collection picker and per-design appearance preferences.

## Next: choose and implement the collection

- Iterate on the HTML gallery and choose which designs to ship.
- Port selected artwork to native QML, driven by actual weather and each city's time.
- Choose one carefully composed default that works before opening Customize.
- Add a small Customize menu with persisted choices: compact/expanded weather,
  clocks and calendar, calendar visibility, cities, units, and bar content/format.
- Keep the selected visual designs available without multiplying settings for
  every design; distinguish shared preferences from genuinely design-specific ones.
- Curate the prototype controls before porting them: artwork strength and lettering
  are experiments, not automatic additions to the native menu.
- Provide a quiet/reduced-motion option and respect desktop light/dark mode.
- Keep deeper artwork, layout and behavior customization accessible through readable
  source and documented configuration, including agent-assisted edits.
- Make locations editable; remove fixed country indexes and city-count assumptions.

## Before release and marketplace submission

- Audit settings persistence and IPC against current third-party shell APIs.
- Test clean installation without reliance on built-in clock clone routing.
- Verify open/close, format cycling, reload, disable/re-enable and removal.
- Validate both palettes, offline operation, timezone changes and network failures.
- Document configuration and add final light/dark screenshots.
- Submit to the marketplace after review of the finished plugin.
