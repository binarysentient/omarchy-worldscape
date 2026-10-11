# Worldscape design principles

**Opinionated by default. Malleable by design.**

Worldscape follows three layers: a finished recipe, a few useful adjustments,
and the freedom to make something entirely your own. These principles guide
what we build; they do not imply that every feature below is implemented today.

## 1. Serve our best recipe first

Opening the widget should immediately feel good. We choose the composition,
information hierarchy, typography, spacing, artwork and motion together. The
first-run experience should need no appearance configuration to look finished.

- Make time, date and weather easy to read at a glance.
- Let weather and each city's time of day give the artwork its mood.
- Fit both desktop light and dark palettes without sacrificing contrast.
- Keep motion gentle, optional and subordinate to information.
- Treat compact and expanded compositions as designed layouts, not merely scaled
  copies. Both should feel intentional.
- Keep the clock responsive when weather is slow or unavailable. Make stale data
  understandable and keep the last useful forecast available.

We can offer several curated designs, but we still choose and polish a default.
Installing a clock should not begin with a design assignment.

## Auto is the default

Worldscape should belong to the active Omarchy theme without configuration.
Use the theme's actual palette and declared light/dark mode. For familiar themes,
choose a considered illustration treatment that suits their visual character.
For a new user theme, infer the closest treatment from palette characteristics
rather than requiring a hardcoded name. This is local, deterministic matching;
no agent or remote AI is needed at runtime.

Keep theme color and scene meaning separate: a dark interface can show a bright
sunny afternoon, and a light interface can show a moonlit city. Each scene follows
its city's time of day and actual weather. The palette makes it feel at home;
weather and daylight make it feel alive.

Offer a small manual override when Auto does not express someone's taste. A user
may combine their desktop palette with another illustration treatment; shared
information preferences should remain intact. Name the resolved treatment clearly
and keep returning to Auto easy. Describe theme samples as representative unless
we have evidence of popularity; do not present a popularity ranking as fact.

## 2. Offer a few useful recipe adjustments

Customize is for common decisions someone can make quickly and confidently.
Changing an option should produce an immediately understandable, well-composed
result, and should be easy to undo.

| Area | Everyday choices |
| --- | --- |
| Weather | Compact or expanded view; temperature units |
| World clocks | Compact or expanded view; which cities to show; 12/24-hour time |
| Calendar | Show or hide; compact or expanded view; week start |
| Bar | Which date, time and weather elements appear; a few useful formats |
| Appearance | A curated design; quiet or animated presentation |

This table defines the intended scope, not a promise of one separate control for
every row or sub-item. Group related choices and reveal details only where they
are useful. Compact/expanded choices can be independent where that serves the
composition; the default should remain coherent without adjusting them.

Prefer named choices such as **Compact** and **Expanded** over exposing geometry.
Formats should have readable previews. Reuse the desktop's theme and conventions.
Keep a clear way back to defaults.

Shared choices—cities, units, visibility, formats—should survive switching designs.
A design may remember its own limited appearance settings where needed. Avoid
making users repeat the same choices for every visual design.

The HTML lab can explore more controls than the shipped widget. A prototype knob
does not automatically earn a place in Customize. Keep it only when it solves a
common need better than a thoughtfully chosen default.

## 3. Leave the whole recipe open

The built-in menu is not a ceiling. Users and their agents should be able to
change anything the source permits: scenes, typography, panel layout, interactions,
locations, forecast presentation, data providers, or the entire experience.

Support that freedom with readable QML, ordinary configuration files, clear names,
and focused helpers. Keep boundaries between presentation, time calculations and
weather fetching understandable. Document where to start for common edits and
how to check the result. Favor direct, understandable changes over a speculative
extension framework or a settings system for every possible preference.

Make local experimentation reversible. Explain how updates affect local edits
and offer a documented fork workflow before claiming customizations survive
updates. Do not promise automatic merging or agent integrations we have not built.

Agent assistance is an optional way to work on an open plugin, not a runtime
dependency. The widget must remain useful without an agent or an AI service.

## How we decide what belongs

For each proposal, ask:

1. Does this improve the default experience? If so, consider making it the default.
2. Is this a common, understandable choice? If so, it may belong in Customize.
3. Is this a personal or structural change? Keep it possible through the source;
   document the relevant entry point rather than adding another permanent control.

A menu option needs a clear use, a readable name and a good result in every
supported design. A visual effect needs to earn its space without obscuring the
information. A source change should remain understandable to the next person or
agent who opens it.
