// Scene math for the city windows: colour mixing, sunrise/sunset, the sky
// gradient through a day, and how a weather code reads as a scene. Pure
// functions only, so the art stays a function of (time, place, weather, style).

// ---- Colour helpers. Colours travel as "#rrggbb" strings; QML colours are
//      accepted too (they expose r/g/b in 0..1).

function hex(value) {
  if (value === undefined || value === null) return "#000000"
  if (typeof value === "object" && value.r !== undefined) return toHex([value.r * 255, value.g * 255, value.b * 255])
  var s = String(value)
  if (/^#[0-9a-fA-F]{8}$/.test(s)) return "#" + s.slice(3).toLowerCase() // #aarrggbb from Qt
  if (/^#[0-9a-fA-F]{6}$/.test(s)) return s.toLowerCase()
  return "#000000"
}

function rgb(h) {
  h = hex(h)
  return [parseInt(h.substr(1, 2), 16), parseInt(h.substr(3, 2), 16), parseInt(h.substr(5, 2), 16)]
}

function toHex(a) {
  var out = "#"
  for (var i = 0; i < 3; i++) {
    var v = Math.round(Math.max(0, Math.min(255, a[i])))
    out += (v < 16 ? "0" : "") + v.toString(16)
  }
  return out
}

function mix(a, b, t) {
  var A = rgb(a), B = rgb(b)
  return toHex([A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t, A[2] + (B[2] - A[2]) * t])
}

function luminance(h) {
  var c = rgb(h)
  return (c[0] * 0.299 + c[1] * 0.587 + c[2] * 0.114) / 255
}

// ---- Sun. NOAA's low-precision equations: good to a couple of minutes,
//      which is plenty for deciding when lamps come on. Works offline for any
//      coordinates, so old caches without sunrise data still get real times.
//      Returns local hours (0..24) or polar flags.

function solarDay(latitude, longitude, utcMs, offsetMinutes) {
  var lat = Number(latitude), lon = Number(longitude)
  if (!isFinite(lat) || !isFinite(lon)) return { sunrise: 6.5, sunset: 18.5, polar: "", estimated: true }
  var local = new Date(utcMs + offsetMinutes * 60000)
  var start = Date.UTC(local.getUTCFullYear(), 0, 1)
  var dayOfYear = Math.floor((local.getTime() - start) / 86400000) + 1
  var g = 2 * Math.PI / 365 * (dayOfYear - 1)
  var eqtime = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g)
    - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g))
  var decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g) - 0.006758 * Math.cos(2 * g)
    + 0.000907 * Math.sin(2 * g) - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g)
  var phi = lat * Math.PI / 180
  var cosH = Math.cos(90.833 * Math.PI / 180) / (Math.cos(phi) * Math.cos(decl)) - Math.tan(phi) * Math.tan(decl)
  if (cosH > 1) return { sunrise: 12, sunset: 12, polar: "night", estimated: false }
  if (cosH < -1) return { sunrise: 0, sunset: 24, polar: "day", estimated: false }
  var ha = Math.acos(cosH) * 180 / Math.PI
  var rise = 720 - 4 * (lon + ha) - eqtime + offsetMinutes
  var set = 720 - 4 * (lon - ha) - eqtime + offsetMinutes
  return { sunrise: wrapHours(rise / 60), sunset: wrapHours(set / 60), polar: "", estimated: false }
}

function wrapHours(h) { return ((h % 24) + 24) % 24 }

// ---- Sky through the day. Keyframes are placed relative to this city's own
//      sunrise and sunset, so London in December and Vadodara in June both
//      get a believable dawn. Each entry is [hour, top, bottom].

var NIGHT = ["#0a1230", "#23305a"]
var FIRST = ["#2a3266", "#6c5a8e"]
var RISE = ["#48508a", "#f4a582"]
var DAY = ["#3f8fd8", "#bfe2f5"]
var GOLD = ["#4f7fc4", "#f6c27a"]
var SET = ["#352e66", "#f2865a"]

function keyframes(sun) {
  if (sun.polar === "day") return [[0, DAY[0], DAY[1]], [24, DAY[0], DAY[1]]]
  if (sun.polar === "night") return [[0, NIGHT[0], NIGHT[1]], [24, NIGHT[0], NIGHT[1]]]
  var sr = Math.max(2, Math.min(11, sun.sunrise))
  var ss = Math.max(sr + 4, Math.min(22.5, sun.sunset))
  var raw = [[0, NIGHT], [sr - 1.4, NIGHT], [sr - 0.6, FIRST], [sr, RISE], [sr + 1.5, DAY],
             [ss - 1.5, DAY], [ss - 0.5, GOLD], [ss + 0.2, SET], [ss + 1.2, NIGHT], [24, NIGHT]]
  var out = []
  for (var i = 0; i < raw.length; i++) {
    var t = Math.max(0, Math.min(24, raw[i][0]))
    if (out.length && t <= out[out.length - 1][0]) continue
    out.push([t, raw[i][1][0], raw[i][1][1]])
  }
  return out
}

function skyAt(hour, sun) {
  var k = keyframes(sun)
  for (var i = 1; i < k.length; i++) {
    if (hour <= k[i][0]) {
      var a = k[i - 1], b = k[i], t = (hour - a[0]) / Math.max(0.0001, b[0] - a[0])
      return [mix(a[1], b[1], t), mix(a[2], b[2], t)]
    }
  }
  return [k[0][1], k[0][2]]
}

function isNight(hour, sun) {
  if (sun.polar) return sun.polar === "night"
  return hour < sun.sunrise - 0.3 || hour > sun.sunset + 0.3
}

function phase(hour, sun) {
  if (sun.polar === "day") return "Midnight sun"
  if (sun.polar === "night") return "Polar night"
  var sr = sun.sunrise, ss = sun.sunset
  if (hour < sr - 1.2 || hour > ss + 1.3) return "Night"
  if (hour < sr) return "First light"
  if (hour < sr + 1) return "Sunrise"
  if (hour < 12) return "Morning"
  if (hour < ss - 1.2) return "Afternoon"
  if (hour < ss) return "Golden hour"
  return "Dusk"
}

// Where the sun or moon sits on its arc: 0 at the eastern horizon, 1 at the
// western one. The moon simply takes the night half of the same arc.
function arcProgress(hour, sun) {
  var sr = sun.sunrise, ss = sun.sunset
  if (sun.polar === "day") return 0.5
  if (sun.polar === "night") return 0.5
  if (!isNight(hour, sun)) return Math.max(0, Math.min(1, (hour - sr) / Math.max(1, ss - sr)))
  var nightLength = 24 - ss + sr
  var into = hour > ss ? hour - ss : hour + 24 - ss
  return Math.max(0, Math.min(1, into / Math.max(1, nightLength)))
}

// Style tint: the sky stays natural, nudged toward the theme so the window
// belongs to the desktop without losing day/night meaning.
function tint(c, style, pal) {
  if (style === "ink") return mix(c, pal.bg, 0.45)
  if (style === "neon") return mix(mix(c, "#000000", 0.35), pal.accent, 0.22)
  if (style === "woodblock") return mix(c, pal.warm, 0.16)
  return mix(c, pal.accent, 0.1)
}

// ---- Weather. Open-Meteo WMO codes reduced to what the scene can draw.
//      "unknown" means no forecast at all and is drawn honestly as such.

function weatherKind(code) {
  if (code === undefined || code === null || code === "") return "unknown"
  var c = Number(code)
  if (!isFinite(c)) return "unknown"
  if (c === 0) return "clear"
  if (c === 1 || c === 2) return "partly"
  if (c === 3) return "cloud"
  if (c === 45 || c === 48) return "fog"
  if (c >= 95) return "storm"
  if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow"
  if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rain"
  return "cloud"
}

function conditionName(code) {
  if (code === undefined || code === null || code === "") return "Unavailable"
  var c = Number(code)
  if (c === 0) return "Clear"
  if (c === 1) return "Mostly clear"
  if (c === 2) return "Partly cloudy"
  if (c === 3) return "Overcast"
  if (c === 45 || c === 48) return "Fog"
  if (c >= 51 && c <= 57) return "Drizzle"
  if (c >= 61 && c <= 67) return "Rain"
  if (c >= 71 && c <= 77) return "Snow"
  if (c >= 80 && c <= 82) return "Rain showers"
  if (c === 85 || c === 86) return "Snow showers"
  if (c >= 95) return "Thunderstorms"
  return "Weather"
}

// Local wall-clock for a UTC instant and a fixed offset. Uses UTC getters on
// a shifted date so the desktop's own timezone never leaks in.
function cityTime(utcMs, offsetMinutes, h24) {
  var d = new Date(utcMs + offsetMinutes * 60000)
  var h = d.getUTCHours(), m = d.getUTCMinutes()
  var mm = (m < 10 ? "0" : "") + m
  return {
    hour: h + m / 60,
    text: h24 ? ((h < 10 ? "0" : "") + h + ":" + mm) : ((h % 12 || 12) + ":" + mm),
    suffix: h24 ? "" : (h < 12 ? "AM" : "PM"),
    day: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getUTCDay()] + " " + d.getUTCDate()
  }
}

// Offset in minutes for a helper row. New helpers send it; older snapshots
// only carry "HH:MM", so infer the nearest quarter hour from that.
function rowOffset(row, utcMs) {
  if (row && typeof row.utcOffsetMinutes === "number" && isFinite(row.utcOffsetMinutes)) return row.utcOffsetMinutes
  var m = /^(\d{1,2}):(\d{2})/.exec(String(row && row.time || ""))
  if (!m) return -new Date(utcMs).getTimezoneOffset()
  var now = new Date(utcMs)
  var diff = (Number(m[1]) * 60 + Number(m[2])) - (now.getUTCHours() * 60 + now.getUTCMinutes())
  diff = ((diff + 720) % 1440 + 1440) % 1440 - 720
  return Math.round(diff / 15) * 15
}

var MOODS = {
  clear: ["Clear and bright", "A clear, starry night"],
  partly: ["Sun between the clouds", "Clouds drifting past the moon"],
  cloud: ["Soft grey light", "Clouds over the city glow"],
  rain: ["Rain on the windows", "Rain through the streetlights"],
  snow: ["Snow settling in", "Quiet snowfall"],
  storm: ["Thunder rolling in", "A storm in the dark"],
  fog: ["Fog softens everything", "Fog around the lamps"],
  unknown: ["No forecast yet", "No forecast yet"]
}

function mood(kind, night) {
  var m = MOODS[kind] || MOODS.unknown
  return m[night ? 1 : 0]
}

if (typeof module !== "undefined") {
  module.exports = { hex: hex, mix: mix, luminance: luminance, solarDay: solarDay, keyframes: keyframes,
    skyAt: skyAt, isNight: isNight, phase: phase, arcProgress: arcProgress, tint: tint,
    weatherKind: weatherKind, conditionName: conditionName, cityTime: cityTime, rowOffset: rowOffset, mood: mood }
}
