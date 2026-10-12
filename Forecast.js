// Forecast reading for the sill strip, the "what's next" line, the calendar
// glyphs and the city focus view. Pure functions over an Open-Meteo report
// (daily + hourly in the city's own timezone). Temperatures stay in °C;
// callers convert for display. Older cached reports may lack any of these
// fields, so every function returns an empty result rather than throwing.

var DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var FULL_DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

function pad2(n) { return (n < 10 ? "0" : "") + n }

// The city's wall-clock as Open-Meteo keys: "YYYY-MM-DD" and "YYYY-MM-DDTHH".
function localKeys(utcMs, offsetMinutes) {
  var d = new Date(utcMs + offsetMinutes * 60000)
  var date = d.getUTCFullYear() + "-" + pad2(d.getUTCMonth() + 1) + "-" + pad2(d.getUTCDate())
  return { date: date, hour: date + "T" + pad2(d.getUTCHours()) }
}

function num(list, i) {
  if (!list || i >= list.length) return null
  var v = list[i]
  return v === null || v === undefined || !isFinite(Number(v)) ? null : Number(v)
}

// Whole days from `fromKey` to `toKey` ("YYYY-MM-DD"), or NaN.
function dayOffset(fromKey, toKey) {
  return Math.round((Date.parse(String(toKey) + "T00:00:00Z") - Date.parse(String(fromKey) + "T00:00:00Z")) / 86400000)
}

function weekday(dateKey) {
  var d = new Date(String(dateKey) + "T12:00:00Z")
  return isNaN(d.getTime()) ? -1 : d.getUTCDay()
}
function dayName(dateKey) { var w = weekday(dateKey); return w < 0 ? "" : DAY_NAMES[w] }
function fullDayName(dateKey) { var w = weekday(dateKey); return w < 0 ? "" : FULL_DAY_NAMES[w] }

// Up to `count` days starting at `todayKey` (the city's own date). Each day
// carries `offset` (0 today, 1 tomorrow…) so callers never infer "today" from
// array position; a day missing a temperature keeps its slot with nulls.
function days(report, todayKey, count) {
  var daily = report && report.daily ? report.daily : null
  if (!daily || !daily.time) return []
  var out = []
  for (var i = 0; i < daily.time.length && out.length < count; i++) {
    var key = String(daily.time[i])
    if (key < todayKey) continue
    out.push({
      key: key,
      offset: dayOffset(todayKey, key),
      name: dayName(key),
      code: num(daily.weather_code, i),
      hi: num(daily.temperature_2m_max, i),
      lo: num(daily.temperature_2m_min, i),
      chance: num(daily.precipitation_probability_max, i),
      sunrise: daily.sunrise && daily.sunrise[i] ? String(daily.sunrise[i]).slice(11, 16) : "",
      sunset: daily.sunset && daily.sunset[i] ? String(daily.sunset[i]).slice(11, 16) : ""
    })
  }
  return out
}

// Up to `count` hours starting with the one containing now. Hourly times are
// local to the offset in force when the report was fetched
// (`utc_offset_seconds`), so they are turned into instants first: a report
// fetched just before a DST change still lines up afterwards. Hours are
// labelled with each slot's own offset (`utc_offset_minutes`, added by
// weather.py from tzdata), else the city's current offset. A cache too old to cover the
// current hour yields nothing rather than a stale line.
function hours(report, utcMs, offsetMinutes, count) {
  var hourly = report && report.hourly ? report.hourly : null
  if (!hourly || !hourly.time) return []
  var fetchedOffset = isFinite(Number(report.utc_offset_seconds)) ? Number(report.utc_offset_seconds) : offsetMinutes * 60
  var out = []
  for (var i = 0; i < hourly.time.length && out.length < count; i++) {
    var start = Date.parse(String(hourly.time[i]).slice(0, 16) + ":00Z") - fetchedOffset * 1000
    if (!isFinite(start) || start + 3600000 <= utcMs) continue
    var t = num(hourly.temperature_2m, i)
    if (t === null) continue
    var own = hourly.utc_offset_minutes ? num(hourly.utc_offset_minutes, i) : null
    out.push({ start: start, hour: new Date(start + (own === null ? offsetMinutes : own) * 60000).getUTCHours(), temp: t,
               chance: num(hourly.precipitation_probability, i), code: num(hourly.weather_code, i) })
  }
  return out.length && out[0].start <= utcMs ? out : []
}

function isWet(code) {
  if (code === null || code === undefined) return false
  var c = Number(code)
  return (c >= 51 && c <= 67) || (c >= 71 && c <= 77) || (c >= 80 && c <= 86) || c >= 95
}

function wetName(code) {
  var c = Number(code)
  if (c >= 51 && c <= 57) return "Drizzle"
  if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "Snow"
  if (c >= 80 && c <= 82) return "Showers"
  if (c >= 95) return "Storms"
  return "Rain"
}

// The one change worth reading in the next 12 hours, or null when nothing
// changes (the sill then keeps its mood line). Structured, so the caller
// formats hours and temperatures in the user's units.
function nextChange(report, utcMs, offsetMinutes) {
  var current = report && report.current ? report.current : null
  var h = hours(report, utcMs, offsetMinutes, 13)
  if (!current || h.length < 3) return null
  var nowTemp = Number(current.temperature_2m)
  var wetNow = isWet(current.weather_code)
  var i, j

  if (!wetNow) {
    for (i = 1; i < h.length; i++) {
      if (isWet(h[i].code) && (h[i].chance === null || h[i].chance >= 40)) {
        var peak = 0
        for (j = i; j < h.length; j++) if (h[j].chance !== null) peak = Math.max(peak, h[j].chance)
        return { kind: "wet", hour: h[i].hour, code: h[i].code, chance: peak || null, label: wetName(h[i].code) }
      }
    }
  } else {
    for (i = 1; i + 1 < h.length; i++) {
      if (!isWet(h[i].code) && !isWet(h[i + 1].code) && (h[i].chance === null || h[i].chance < 30))
        return { kind: "dry", hour: h[i].hour, code: h[i].code, chance: null, label: "Clearing" }
    }
  }

  var hot = null, cold = null
  for (i = 1; i < h.length; i++) {
    if (!hot || h[i].temp > hot.temp) hot = h[i]
    if (!cold || h[i].temp < cold.temp) cold = h[i]
  }
  if (hot && hot.temp >= 32 && hot.temp >= nowTemp + 2)
    return { kind: "heat", hour: hot.hour, code: 0, chance: null, temp: hot.temp, label: "Up to" }
  if (cold && nowTemp > 1 && cold.temp <= 0)
    return { kind: "frost", hour: cold.hour, code: 71, chance: null, temp: cold.temp, label: "Frost" }
  return null
}

if (typeof module !== "undefined") {
  module.exports = { localKeys: localKeys, dayOffset: dayOffset, dayName: dayName, fullDayName: fullDayName, days: days,
    hours: hours, isWet: isWet, wetName: wetName, nextChange: nextChange }
}
