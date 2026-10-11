# Worldscape roadmap

## Working baseline

- Native calendar, world clocks and cached weather from the existing widget.
- Standalone plugin identity and isolated weather cache.
- Interactive HTML studies for five illustrated designs in day/night palettes.
- Prototype collection picker and per-design appearance preferences.

## Next: choose and implement the collection

- Iterate on the HTML gallery and choose which designs to ship.
- Port selected artwork to native QML, driven by actual weather and each city's time.
- Add a Customize button, design switcher and persisted per-design settings.
- Artwork strength, spacing, clock lettering, 12/24-hour format, calendar/forecast
  visibility, and motion controls, including reduced-motion behavior.
- Make locations editable; remove fixed country indexes and city-count assumptions.

## Before release and marketplace submission

- Audit settings persistence and IPC against current third-party shell APIs.
- Test clean installation without reliance on built-in clock clone routing.
- Verify open/close, format cycling, reload, disable/re-enable and removal.
- Validate both palettes, offline operation, timezone changes and network failures.
- Document configuration and add final light/dark screenshots.
- Submit to the marketplace after review of the finished plugin.
