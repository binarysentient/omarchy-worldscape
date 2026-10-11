import QtQuick
import qs.Commons
import "Sky.js" as Sky
import "WeatherModel.js" as WeatherModel

// A city window with its information on the sill below. Text always sits on
// the panel's own background, never on the artwork.
Column {
  id: root

  property var row: ({})
  property real utcMs: Date.now()
  property int offsetMinutes: 0
  property bool compact: false
  property bool h24: true
  property bool imperial: false
  property bool animate: false
  property string style: "glass"
  property var pal: ({})
  property var type: ({ family: Style.font.family, weight: Font.Light, upper: false, track: 0, italicMood: false, timeSize: 38 })
  property color ink: Color.popups.text
  property color dim: ink
  property color accent: Color.accent

  readonly property var current: row && row.report && row.report.current ? row.report.current : null
  readonly property var daily: row && row.report && row.report.daily ? row.report.daily : null
  readonly property var clock: Sky.cityTime(utcMs, offsetMinutes, h24)
  readonly property bool hasWeather: current !== null && current.temperature_2m !== undefined && current.temperature_2m !== null
  readonly property string iconFont: Style.font.family

  function temp(c) {
    if (c === undefined || c === null || c === "" || !isFinite(Number(c))) return "—"
    return Math.round(imperial ? Number(c) * 9 / 5 + 32 : Number(c)) + "°"
  }
  function todayRange() {
    if (!daily || !daily.time || !daily.temperature_2m_max) return ""
    var today = current && current.time ? String(current.time).slice(0, 10) : ""
    var i = Math.max(0, daily.time.indexOf(today))
    return "H " + temp(daily.temperature_2m_max[i]) + " · L " + temp(daily.temperature_2m_min ? daily.temperature_2m_min[i] : null)
  }
  readonly property string statusLine: !hasWeather ? (row && row.error ? row.error : "Weather unavailable")
    : row.stale ? "Saved forecast · offline"
    : todayRange()

  spacing: Style.space(8)

  CityWindow {
    id: art
    width: root.width
    height: root.compact ? Style.space(88) : Style.space(196)
    city: root.row.city || ""
    region: root.row.region || ""
    latitude: root.row.latitude
    longitude: root.row.longitude
    utcMs: root.utcMs
    offsetMinutes: root.offsetMinutes
    weatherCode: root.hasWeather ? root.current.weather_code : null
    style: root.style
    compact: root.compact
    animate: root.animate
    pal: root.pal
  }

  Column {
    width: root.width
    spacing: Style.space(2)

    Row {
      width: parent.width
      spacing: Style.space(6)
      Rectangle {
        visible: !!root.row.local
        width: Style.space(6); height: width; radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.accent
      }
      Text {
        width: parent.width - (root.row.local ? Style.space(12) : 0)
        text: root.type.upper ? String(root.row.city || "").toUpperCase() : (root.row.city || "")
        elide: Text.ElideRight
        color: root.row.local ? root.ink : root.dim
        font.family: root.type.family
        font.pixelSize: Style.font.bodySmall
        font.letterSpacing: root.type.track
        font.bold: !!root.row.local
      }
    }

    Row {
      spacing: Style.space(4)
      Text {
        id: time
        text: root.clock.text
        color: root.ink
        font.family: root.type.family
        font.weight: root.type.weight
        font.pixelSize: Style.space(root.compact ? 24 : root.type.timeSize)
      }
      Text {
        visible: text !== ""
        anchors.baseline: time.baseline
        text: root.clock.suffix
        color: root.dim
        font.family: root.type.family
        font.pixelSize: Style.font.bodySmall
      }
    }

    Text {
      width: parent.width
      text: Sky.phase(art.hour, art.sun) + " · " + root.clock.day + " · " + (root.row.abbreviation || "")
        + (!root.row.local && root.row.difference ? " · " + root.row.difference : "")
      elide: Text.ElideRight
      color: root.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Row {
      width: parent.width
      spacing: Style.space(6)
      topPadding: Style.space(4)
      Text {
        text: root.hasWeather ? WeatherModel.iconForOpenMeteoCode(root.current.weather_code, root.current.is_day === 0) : "—"
        color: root.hasWeather ? root.accent : root.dim
        font.family: root.iconFont
        font.pixelSize: Style.font.title
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: root.temp(root.hasWeather ? root.current.temperature_2m : null)
        color: root.hasWeather ? root.accent : root.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        width: parent.width - x
        text: root.hasWeather ? Sky.conditionName(root.current.weather_code) : "No forecast"
        elide: Text.ElideRight
        color: root.ink
        font.family: root.type.family
        font.pixelSize: Style.font.bodySmall
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      visible: !root.compact && root.hasWeather
      width: parent.width
      text: Sky.mood(art.kind, art.night)
      elide: Text.ElideRight
      color: root.dim
      font.family: root.type.family
      font.italic: root.type.italicMood
      font.pixelSize: Style.font.bodySmall
    }

    Text {
      visible: !root.compact || !root.hasWeather || !!root.row.stale
      width: parent.width
      text: root.statusLine
      elide: Text.ElideRight
      color: root.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
