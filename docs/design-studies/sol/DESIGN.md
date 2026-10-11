# Horizon — Sol's independent direction

My recommendation is to make Worldscape a **window on your day**, rather than a collection of equally weighted cards. One generous landscape gives home time and weather a memorable place. Small horizons show that London, Bengaluru and Tokyo occupy the same moment under different skies. An editorial calendar stays useful without competing with the clock.

The default is Auto. The first view should already feel finished; a user should not have to art-direct a weather widget. The serif numerals, generous landscape, quiet divider rules and small typographic annotations form one recipe. This direction trades maximum information density for atmosphere and a clear hierarchy. Compact is a deliberately simpler composition: shorter home scene, no city thumbnails or forecast, tighter calendar.

## Open the study

Open `index.html` directly in any modern browser. It is standalone and offline: the theme snapshots and procedural SVG artwork are inline, with system fonts and no remote assets. `themes.json` preserves the read-only source snapshot taken from `/usr/share/omarchy/themes/*/colors.toml` on October 11, 2026. These are representative included themes, not a popularity ranking.

The simulation controls below the widget are design-lab tools, separate from the small Customize dialog. Toronto's time slider moves all world clocks together; London retains rain while the other cities demonstrate clear skies. The date is deliberately fixed to Sunday October 11, 2026. Weather and all temperatures are illustrative. Calendar navigation is real month arithmetic. This prototype does not fetch weather, change the live widget, change Omarchy, or read desktop configuration at runtime.

## Auto, theme matching, and combinations

Auto has two independent jobs:

1. **Honor the desktop.** Use the active theme's own background, foreground, accent and surface roles for the interface. Do not replace a new theme with a known theme. Maintain contrast: the prototype checks body text against background and substitutes a readable foreground if a custom palette is unsafe.
2. **Choose a compatible illustration material.** Match the new theme to representative anchors using weighted perceptual color distance, then use the anchor's material: cool luminous palettes → Ink; warmer earthy palettes → Paper; muted blue/green palettes → Mineral. A short visible explanation tells the user what Auto chose.

This implementation converts colors to OKLab and scores background (40%), foreground (20%) and accent (40%), with a light/dark mismatch penalty. Installed themes use the same mechanism; custom Background, Foreground and Accent controls immediately demonstrate matching without requiring a reload. This is a compact, deterministic demonstrator, not a claim of aesthetic intelligence. A production matcher should compare several chromatic roles, hue/chroma distribution and contrast character; use a normalized score and margin to avoid overconfident matches. For ambiguous or very unfamiliar palettes, use a neutral material with the exact theme colors. Recompute on theme change, not on a timer. Add hysteresis if a theme editor streams changes.

The actual sky remains independent of the UI scheme. A dark desktop can show a bright afternoon; a light desktop can show a deep night. Daylight determines sky luminance, sun/moon/stars and the warm horizon. Rain changes cloud mass, palette and falling strokes; snow adds slow flakes and snow caps; fog places moving veils between landscape layers; storms add restrained, infrequent lightning. Night weather keeps its dark luminance. Gentle motion respects both Customize and `prefers-reduced-motion`.

Manual overrides are explicit and reversible. Select Ink, Paper or Mineral to pin the material. “Combine the recipe” can borrow a named landscape palette or use a natural sky while retaining the desktop interface. Shared preferences persist through theme/material changes in browser localStorage. Reset restores all defaults. In the shipped widget, persist only a small settings object; theme changes must never overwrite city, format or calendar preferences.

For production, calculate daylight from each city's actual timezone and solar position. Latitude, season and cloud cover should shape daylight transitions; the demo's hour thresholds are intentionally approximate. Preserve the last useful weather result and its timestamp; keep clocks running when the network fails. No runtime AI is needed.

## Everyday customization

Customize contains six decisions: Expanded/Compact, calendar visibility, 12/24-hour clock, Celsius/Fahrenheit, bar contents with previews, and gentle motion. The experimental material and combination controls remain below the study, not additional first-run settings. The full source remains the escape hatch for composition, typography and artwork.

The standalone file has ordinary, named boundaries: `currentTheme`, `closest`, `getRecipe`, `scene`, `drawCalendar`, and `render`. A native implementation should keep these responsibilities separated between QML presentation, theme-role/matching helpers, and time/weather models. This study does not imply all its controls belong in the released product.

## Validation

`verify.py` uses a local ChromeDriver on port 9517 through the standard WebDriver HTTP protocol; no Python packages are required. Run ChromeDriver separately, then run this file from the repository root. It checks 225 combinations of nine theme choices, five weather conditions and five times; custom palette updates; compact/calendar/format behavior; settings persistence; dialog/reset behavior; and narrow viewport overflow. The browser reported no severe console errors. Desktop, light-interface/night-scene, and mobile screenshots were visually inspected. JavaScript also passes a standalone syntax parse.

Artifacts: `preview-desktop.png`, `preview-light-night.png`, `preview-mobile.png`. The interface is a design study, not a verified native QML layout. Weather is simulated, the artwork is schematic, and the calendar has no event integration.

Attribution for a future commit: `Co-authored-by: Codex <noreply@openai.com>`.
