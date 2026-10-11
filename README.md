# Worldscape

A calendar, world-clock and weather plugin for the Omarchy shell. Four cities,
one panel, with light and dark palettes inherited from your desktop theme.

**Development preview — not a stable release.** The native widget currently
provides the original calendar and weather layout. Illustrated designs and the
Customize interface are interactive HTML prototypes, pending their QML implementation.
The repository has not been submitted to the Omarchy plugin marketplace.

## Install the development version

Requires Omarchy's Quickshell-based shell (baseline: Omarchy 4.0.4), Python 3.9+
with system timezone data, and the shell's Nerd Font glyphs. Other Omarchy
versions have not yet been verified.

```bash
omarchy plugin add https://github.com/binarysentient/omarchy-worldscape.git --enable
```

Plugin ID: `io.github.binarysentient.worldscape`.
This is a separate widget; it does not automatically replace the built-in clock
or an existing personal clock clone. Arrange or disable those through Omarchy's
bar/plugin controls after trying it.

Click the clock to open the panel; right-click cycles the bar's date formats;
middle-click opens Omarchy's timezone picker. Both theme modes follow the shell.

## Design lab

Open [docs/design-lab/index.html](docs/design-lab/index.html) locally in a browser.
It includes Atmosphere, Paper Worlds, Pixel Postcards, Observatory and Field Notes,
with paired day/night previews. Try the weather selector, hour slider, and Customize
button. Keep multiple designs and adjust each design independently; these choices
are saved in that browser's local storage, not in your live desktop configuration.
The data and date in this prototype are illustrative, not live forecasts.

## Locations and privacy

`locations.json` currently defines four example cities, their IANA timezones and
coordinates. Edit existing entries in the installed plugin to change cities.
The current implementation assumes four cards; arbitrary city counts and an
in-widget location editor are planned. Update `country` alongside city/coordinates.

Weather requests go directly to [Open-Meteo](https://open-meteo.com/), using the
configured coordinates. Forecasts are cached for 15 minutes in
`$XDG_CACHE_HOME/omarchy-worldscape` (normally `~/.cache/omarchy-worldscape`).
The clock reads local timezone data and cached weather without waiting on network
requests. Weather refreshes happen separately; the last forecast is retained offline.

Automatic location detection is **disabled by default**. Setting `enabled` to
`true` in `local-location.json` opts into requests to `https://wttr.in/?format=j1`,
which infers a city from your public IP. That legacy feature currently replaces
a matching country card for Canada, the US, the UK or India. A general location
configuration interface is planned. No detected location cache is included here.

## Development

The root `manifest.json` describes the single installable plugin. QML and JS files
implement its bar button and popup; Python helpers provide time and weather data.

```bash
omarchy plugin validate .
python3 -m py_compile combined.py weather.py world_clocks.py
python3 combined.py  # cached/offline clock read; no network request
```

See [the roadmap](docs/ROADMAP.md) for the next steps. The original live widget
is kept separate while this repository is developed.

## Credits and license

MIT; see [LICENSE](LICENSE). Calendar/clock and shared UI logic derive from
[Omarchy](https://github.com/omacom/omarchy), copyright David Heinemeier Hansson.
Worldscape additions and design studies by binarysentient / Thundermonkey.

Weather data by [Open-Meteo](https://open-meteo.com/), under
[CC BY 4.0](https://open-meteo.com/en/licence); API usage is subject to its
[terms](https://open-meteo.com/en/terms). Optional IP-based city lookup uses
[wttr.in](https://github.com/chubin/wttr.in). Fonts come from the host system;
the design lab uses code-drawn artwork and bundles no external graphics or fonts.
