// Auto appearance: which window style suits the active Omarchy theme.
//
// The palette always comes from the live theme (Color.background, foreground,
// accent). This file only decides the illustration treatment and supplies the
// two scene colours the shell does not expose (a warm lamp colour and a ground
// green). Installed themes get a curated pick; any other palette borrows the
// pick of its nearest installed relative in OKLab. Local and deterministic.
//
// Colours are from /usr/share/omarchy/themes/<key>/colors.toml (background,
// foreground, accent). `warm` is usually `yellow` and `green` is `green`; where
// a theme's yellow slot is not a warm colour, a nearby warm tone from that
// theme stands in so night windows still glow like lamps.

var STYLES = ["glass", "woodblock", "ink", "neon"]
var STYLE_NAMES = { glass: "Glass", woodblock: "Woodblock", ink: "Ink", neon: "Neon" }

// key: [name, background, foreground, accent, warm, green, style]
var THEMES = {
  "tokyo-night":      ["Tokyo Night", "#1a1b26", "#a9b1d6", "#7aa2f7", "#e0af68", "#9ece6a", "glass"],
  "catppuccin":       ["Catppuccin", "#1e1e2e", "#cdd6f4", "#89b4fa", "#f9e2af", "#a6e3a1", "glass"],
  "catppuccin-latte": ["Catppuccin Latte", "#eff1f5", "#4c4f69", "#1e66f5", "#df8e1d", "#40a02b", "glass"],
  "rose-pine":        ["Rosé Pine", "#faf4ed", "#575279", "#56949f", "#ea9d34", "#286983", "glass"],
  "ethereal":         ["Ethereal", "#060b1e", "#ffcead", "#7d82d9", "#e9bb4f", "#92a593", "glass"],
  "lumon":            ["Lumon", "#16242d", "#d6e2ee", "#8bc9eb", "#e6c48a", "#5e95bc", "glass"],
  "gruvbox":          ["Gruvbox", "#282828", "#d4be98", "#7daea3", "#d8a657", "#a9b665", "woodblock"],
  "everforest":       ["Everforest", "#2d353b", "#d3c6aa", "#7fbbb3", "#dbbc7f", "#a7c080", "woodblock"],
  "osaka-jade":       ["Osaka Jade", "#111c18", "#c1c497", "#509475", "#e5c736", "#549e6a", "woodblock"],
  "kanagawa":         ["Kanagawa", "#1f1f28", "#dcd7ba", "#dcd7ba", "#c0a36e", "#76946a", "woodblock"],
  "ristretto":        ["Ristretto", "#2c2525", "#e6d9db", "#f38d70", "#f9cc6c", "#adda78", "woodblock"],
  "miasma":           ["Miasma", "#222222", "#c2c2b0", "#78824b", "#b36d43", "#5f875f", "woodblock"],
  "nord":             ["Nord", "#2e3440", "#d8dee9", "#81a1c1", "#ebcb8b", "#a3be8c", "ink"],
  "matte-black":      ["Matte Black", "#121212", "#bebebe", "#e68e0d", "#f59e0b", "#ffc107", "ink"],
  "flexoki-light":    ["Flexoki Light", "#fffcf0", "#100f0f", "#205ea6", "#d0a215", "#879a39", "ink"],
  "solitude":         ["Solitude", "#101315", "#cacccc", "#798186", "#c9c2b4", "#9fa5a9", "ink"],
  "last-horizon":     ["Last Horizon", "#0c0b0c", "#fafcfb", "#b59790", "#d9b58a", "#87a9b0", "ink"],
  "lupine":           ["Lupine", "#fafafa", "#212121", "#3264eb", "#e0a030", "#4a2fd0", "ink"],
  "white":            ["White", "#ffffff", "#000000", "#6e6e6e", "#d8b25a", "#3a3a3a", "ink"],
  "vantablack":       ["Vantablack", "#000000", "#ffffff", "#8d8d8d", "#e2c27a", "#b6b6b6", "ink"],
  "retro-82":         ["Retro 82", "#05182e", "#f6dcac", "#faa968", "#e97b3c", "#028391", "neon"],
  "hackerman":        ["Hackerman", "#0b0c16", "#ddf7ff", "#82fb9c", "#50f7d4", "#4fe88f", "neon"]
}

function normalizedStyle(value) {
  var s = String(value || "").toLowerCase()
  return STYLES.indexOf(s) >= 0 ? s : "auto"
}

function rgb(h) {
  var s = String(h || "#000000")
  if (s.length === 9) s = "#" + s.slice(3)
  return [parseInt(s.substr(1, 2), 16) || 0, parseInt(s.substr(3, 2), 16) || 0, parseInt(s.substr(5, 2), 16) || 0]
}

function oklab(h) {
  var c = rgb(h).map(function(v) {
    v /= 255
    return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
  })
  var l = Math.cbrt(0.4122214708 * c[0] + 0.5363325363 * c[1] + 0.0514459929 * c[2])
  var m = Math.cbrt(0.2119034982 * c[0] + 0.6806995451 * c[1] + 0.1073969566 * c[2])
  var s = Math.cbrt(0.0883024619 * c[0] + 0.2817188376 * c[1] + 0.6299787005 * c[2])
  return [0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
          1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
          0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s]
}

function distance(a, b) {
  var A = oklab(a), B = oklab(b)
  return Math.sqrt(Math.pow(A[0] - B[0], 2) + Math.pow(A[1] - B[1], 2) + Math.pow(A[2] - B[2], 2))
}

// Installed themes ranked by weighted distance: background matters most
// because it sets the mood, then accent, then foreground.
function relatives(bg, fg, accent) {
  var out = []
  for (var key in THEMES) {
    var t = THEMES[key]
    out.push({ key: key, name: t[0], distance: 0.5 * distance(bg, t[1]) + 0.3 * distance(accent, t[3]) + 0.2 * distance(fg, t[2]) })
  }
  out.sort(function(a, b) { return a.distance - b.distance })
  return out
}

// Heuristic closeness for display, not a probability.
function similarity(d) { return Math.max(0, Math.round(100 * (1 - d / 0.4))) }

// Everything the panel needs to explain and draw the Auto choice.
function resolve(bg, fg, accent, override) {
  var ranked = relatives(bg, fg, accent)
  var best = ranked[0]
  var t = THEMES[best.key]
  var exact = best.distance < 0.004
  var pinned = normalizedStyle(override)
  var style = pinned === "auto" ? t[6] : pinned
  return {
    style: style,
    styleName: STYLE_NAMES[style],
    auto: pinned === "auto",
    exact: exact,
    themeName: exact ? t[0] : "",
    relative: t[0],
    relativeScore: similarity(best.distance),
    warm: t[4],
    green: t[5]
  }
}

if (typeof module !== "undefined") {
  module.exports = { STYLES: STYLES, STYLE_NAMES: STYLE_NAMES, THEMES: THEMES, normalizedStyle: normalizedStyle,
    relatives: relatives, similarity: similarity, resolve: resolve }
}
