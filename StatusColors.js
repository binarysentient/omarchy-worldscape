// Separate local-time, actual-condition, and Celsius temperature palettes.
function shade(light, dark, isDark) { return isDark ? dark : light }
function timeColor(time, dark) {
  var h = parseInt(String(time).split(":")[0], 10)
  if (h >= 5 && h < 8) return shade("#a34925", "#ffb184", dark) // dawn peach
  if (h >= 8 && h < 17) return shade("#916000", "#ffd166", dark) // sun gold
  if (h >= 17 && h < 20) return shade("#9c4168", "#ee9bc1", dark) // dusk rose
  if (h >= 20 && h < 23) return shade("#354b92", "#98afff", dark) // night blue
  return shade("#514780", "#b2a7ed", dark) // sleep indigo
}
function temperatureColor(c, dark) {
  if (c === undefined || c === null) return shade("#626a70", "#a5afb7", dark)
  if (c < 2) return shade("#006b88", "#80dfff", dark)
  if (c < 15) return shade("#215bb0", "#82b8ff", dark)
  if (c < 21) return shade("#326b83", "#92cddd", dark)
  if (c < 30) return shade("#916000", "#ffd166", dark)
  if (c < 35) return shade("#a34b00", "#ffad55", dark)
  return shade("#b42328", "#ff777b", dark)
}
function weatherColor(code, night, dark) {
  if (code === undefined || code === null) return shade("#626a70", "#a5afb7", dark)
  if (code <= 2) return night ? shade("#354b92", "#98afff", dark) : shade("#916000", "#ffd166", dark)
  if (code === 3 || code === 45 || code === 48) return shade("#596a7d", "#b0bfce", dark)
  if (code >= 95) return shade("#7443a1", "#cea1ff", dark)
  if ((code >= 71 && code <= 77) || code === 85 || code === 86) return shade("#006b88", "#80dfff", dark)
  return shade("#215bb0", "#82b8ff", dark)
}
