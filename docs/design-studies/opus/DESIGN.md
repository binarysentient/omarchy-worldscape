# Opus study · Windows on the world

A standalone HTML prototype (`index.html`, offline, no network or CDN). Open it
directly in a browser. Optional URL parameters: `?theme=gruvbox&weather=rain&hour=19`.

Author: Claude Opus 5.5 (`claude-opus-5-5`), working as an independent design
collaborator. This is a prototype, not native behavior.

## Design intent

Each city is a **window**. You look through the frame at that city's sky: the
sun or moon on a real arc for its local hour, stars at night, lamps that light up
at dusk, and weather that moves (drifting cloud, falling rain/snow, lightning, fog
bands). The information sits **below** the window, on the sill, on the theme's
solid background. Text never lies over artwork, so time, weather and the calendar
stay readable in every palette, light or dark.

- **Lively but subordinate.** Sky colour is interpolated continuously through
  night → first light → sunrise → day → golden hour → dusk, so scrubbing or
  "Play a day" feels like time passing rather than switching between images.
  Motion is slow and small; the Quiet setting and `prefers-reduced-motion` stop
  it while keeping rain streaks and lightning visible as still frames.
- **Each place is recognisably itself.** Simple landmark silhouettes:
  suburban rooftops (Brampton), hills and palms (Silicon Valley), a clock tower
  (London), a dome and minaret (Vadodara).
- **A day ribbon** under the windows puts every city on one 0–24 h band
  coloured by the sky, so you see at a glance who is asleep and who is at
  golden hour.
- **Calendar** shows a headline day, a one-line home mood ("Rain on the
  windows") and the next sunrise/sunset in Expanded; just the month grid in Compact.

## Four window styles

A style is a whole recipe: typography, frame shape and how the scene is drawn.

| Style | Frame | Scene treatment | Type |
| --- | --- | --- | --- |
| Glass | Arched window | Smooth gradient sky, soft glow | Light sans |
| Woodblock | Matted print | Banded sky in hard steps, earthy ground | Serif, italic mood lines |
| Ink | Thin ruled frame | Line drawing on the theme background, hatch lines in the sky | Bold sans, small caps |
| Neon | Glowing edge | Darkened sky, striped sun, horizon grid | Monospace with glow |

## How Auto works

Auto is the default and chooses **both** palette and style.

1. **Installed themes**: the palette comes from the theme. The style is a curated
   pick (table below). If the user switches desktop theme, both follow.
2. **New or custom themes**: rank the installed themes by perceptual distance in
   OKLab (background 50%, accent 30%, foreground 20%). The closest relative supplies
   the style, plus the warm/green colours used for lamps and ground. The user's own
   background, foreground and accent stay as the palette. The panel shows the top
   three relatives with a similarity score, so the choice is explainable.
3. **Combining styles and palettes**: **Style** and **Palette** are separate
   overrides. Pin only the style (for example, Neon with Nord) and the palette keeps
   following the desktop theme. Pin a palette and it stops following. **Back to
   Auto** clears both.

If **Style** is set to Auto and the palette is pinned, the style follows the pinned
palette's pick.

## Selected themes and picks

Colours come from `/usr/share/omarchy/themes/<name>/colors.toml`. I used
`background`, `lighter_background`, `foreground`, `accent`, `yellow` (warm) and
`green` (ground). Two exceptions: in Osaka Jade and Matte Black, the `yellow`
slot is not yellow, so I used `bright_yellow` and `bright_blue` (amber)
respectively. The secondary text colour is derived by mixing foreground and
background, because some `dark_foreground` values have very low contrast.

I picked these themes to cover the installed set and both modes. **I did not
measure popularity.**

| Theme | Mode | Auto style |
| --- | --- | --- |
| Tokyo Night, Catppuccin | dark | Glass |
| Catppuccin Latte, Rosé Pine | light | Glass |
| Gruvbox, Everforest, Osaka Jade, Kanagawa | dark | Woodblock |
| Nord, Matte Black | dark | Ink |
| Flexoki Light | light | Ink |
| Retro 82 | dark | Neon |

## Proposed and lab-only controls

- **Appearance (proposed to ship):** Style and Palette overrides with Auto as
  the default, and Back to Auto.
- **Customize (proposed to ship):**
  - Compact or Expanded world clocks
  - Calendar: show/hide, Compact or Expanded, week start
  - 12h or 24h time; °C or °F
  - Bar time format and whether the bar shows weather
  - Animated or Quiet motion
  - Reset to defaults

  These are shared preferences and are saved to `localStorage`.
- **Lab only (not proposed for Customize):** simulated desktop theme, custom
  colour pickers, home-time scrubber, Play a day, and a weather override.

## Tradeoffs and limitations

- Sunrise and sunset are fixed at about 07:00 and 18:36 for every city. The
  native widget should use per-city values from the forecast, which Open-Meteo
  provides as `daily.sunrise` and `daily.sunset`.
- Nearest-relative matching is simple and explainable, but it only knows the
  themes listed here. A theme unlike any of them still gets *some* style.
  Overriding the style is the escape hatch.
- Sky colours are natural and lightly tinted toward the theme. That keeps
  "night" legible as night even in light themes, at the cost of perfect palette
  purity inside the window.
- Scrubbing rebuilds the SVGs, which restarts the CSS animations. That is fine
  for a prototype; QML would keep items and animate properties instead.
- Forecasts, cities and the date (Sunday 11 October 2026) are illustrative.

## QML path

- `scene()` maps to a `CityWindow.qml` component: a `Canvas` or `Shape` items for
  sky, sun/moon, land and weather, with `NumberAnimation`s for drift, fall and
  twinkle gated by a `motion` property and the reduced-motion preference.
- `skyAt()`, `phase()` and `tint()` belong in `Model.js` or `WeatherModel.js` as
  pure functions. `relatives()` and the curated table become a small
  `ThemeMatch.js` that reads the active Omarchy `colors.toml`.
- Window style becomes one `style` enum in the plugin settings, alongside
  `palette` (`auto` or a theme name). Shared Customize options stay
  design-independent.
- `Panel.qml` keeps the calendar and adds the cities row and day ribbon.
  `BarWidget.qml` keeps the formats.

## Attribution

This is original artwork and code by Claude Opus 5.5 for this study. The theme
colour values belong to their respective Omarchy theme authors and upstream
projects (Tokyo Night, Catppuccin, Gruvbox, Nord, Everforest, Rosé Pine, Flexoki,
Kanagawa and others). Weather is labelled as Open-Meteo to match the existing
plugin, but no data is fetched.

## Browser review by Codex

Checked 360 combinations (12 representative themes × six weather conditions ×
five times), all four manual styles, custom matching, compact/calendar/format
controls and reset. The desktop run reported no JavaScript exceptions or horizontal
overflow. Screenshots include a light interface with a snowy night scene.
Similarity percentages are heuristic scores, not probabilities. Calendar dates and
month are fixed in this study; the chevrons are decorative. Product badges say
“proposed,” and sample weather is explicitly labelled; none of this is shipped QML.
