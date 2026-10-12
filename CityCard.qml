import QtQuick
import qs.Commons
import "Sky.js" as Sky
import "Forecast.js" as Forecast
import "WeatherModel.js" as WeatherModel

// A city card read top to bottom: when (city, time, date), the window that
// shows both time of day and weather, then the weather itself. Text always
// sits on the panel's own background, never on the artwork. Two faces only: the
// desktop sans for names, time and prose; the shell's mono for data. When
// `clickable`, the whole card opens the city's focus view.
Item {
  id: root

  property var row: ({})
  property real utcMs: Date.now()
  property int offsetMinutes: 0
  property bool compact: false
  property bool weatherExpanded: true
  property bool showStrip: true
  property bool clickable: false
  property real windowHeight: compact ? Style.space(88) : Style.space(196)
  property bool h24: true
  property bool imperial: false
  property bool animate: false
  property string style: "glass"
  property var pal: ({})
  property string sans: "sans-serif"
  property color ink: Color.popups.text
  property color dim: ink
  property color line: dim
  property color accent: Color.accent
  property color warm: accent

  signal focusRequested()

  readonly property var report: row && row.report ? row.report : null
  readonly property var current: report && report.current ? report.current : null
  readonly property var clock: Sky.cityTime(utcMs, offsetMinutes, h24)
  readonly property bool hasWeather: current !== null && current.temperature_2m !== undefined && current.temperature_2m !== null
  readonly property string mono: Style.font.family
  readonly property var forecastDays: Forecast.days(report, Forecast.localKeys(utcMs, offsetMinutes).date, 4)
  readonly property var next: hasWeather ? Forecast.nextChange(report, utcMs, offsetMinutes) : null

  function temp(c) {
    if (c === undefined || c === null || c === "" || !isFinite(Number(c))) return "—"
    return Math.round(imperial ? Number(c) * 9 / 5 + 32 : Number(c)) + "°"
  }
  function hourText(h) {
    return h24 ? (h < 10 ? "0" : "") + h + ":00" : (h % 12 || 12) + (h < 12 ? " AM" : " PM")
  }
  function nextText(n) {
    if (!n) return ""
    if (n.kind === "wet") return n.label + " from ~" + hourText(n.hour)
    if (n.kind === "dry") return "Clearing by ~" + hourText(n.hour)
    if (n.kind === "heat") return "Up to " + temp(n.temp) + " by " + hourText(n.hour)
    return "Frost by ~" + hourText(n.hour)
  }
  function todayRange() {
    var d = forecastDays.length && forecastDays[0].offset === 0 ? forecastDays[0] : null
    return d ? "H " + temp(d.hi) + " · L " + temp(d.lo) : ""
  }
  readonly property bool stripVisible: showStrip && weatherExpanded && hasWeather && forecastDays.length >= 2
  readonly property string statusLine: !hasWeather ? (row && row.error ? row.error : "Weather unavailable")
    : row.stale ? "Saved forecast · offline"
    : todayRange()

  implicitHeight: content.implicitHeight
  height: implicitHeight

  Column {
    id: content
    width: root.width
    spacing: Style.space(8)

    // When: city, time, date.
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
          text: root.row.city || ""
          elide: Text.ElideRight
          color: root.row.local ? root.ink : root.dim
          font.family: root.sans
          font.pixelSize: Style.font.subtitle
          font.weight: root.row.local ? Font.DemiBold : Font.Normal
        }
      }

      Row {
        spacing: Style.space(4)
        Text {
          id: time
          text: root.clock.text
          color: root.ink
          font.family: root.sans
          font.weight: Font.Light
          font.pixelSize: Style.space(root.compact ? 26 : 40)
        }
        Text {
          visible: text !== ""
          anchors.baseline: time.baseline
          text: root.clock.suffix
          color: root.dim
          font.family: root.mono
          font.pixelSize: Style.font.caption
        }
      }

      // The window already shows the time of day; the caption is the date,
      // in the clock's colour, then the zone and offset.
      Row {
        width: parent.width
        Text {
          id: cityDate
          text: root.clock.date
          color: root.ink
          font.family: root.mono
          font.pixelSize: Style.font.caption
        }
        Text {
          width: parent.width - cityDate.width
          text: " · " + (root.row.abbreviation || "")
            + (!root.row.local && root.row.difference ? " · " + root.row.difference : "")
          elide: Text.ElideRight
          color: root.dim
          font.family: root.mono
          font.pixelSize: Style.font.caption
        }
      }
    }

    CityWindow {
      id: art
      width: root.width
      height: root.windowHeight
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

    // Weather under the window: now, what changes next, the coming days.
    Column {
      width: root.width
      spacing: Style.space(2)

      Row {
        width: parent.width
        spacing: Style.space(6)
        Text {
          text: root.hasWeather ? WeatherModel.iconForOpenMeteoCode(root.current.weather_code, root.current.is_day === 0) : "—"
          color: root.hasWeather ? root.accent : root.dim
          font.family: root.mono
          font.pixelSize: Style.font.title
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: root.temp(root.hasWeather ? root.current.temperature_2m : null)
          color: root.hasWeather ? root.accent : root.dim
          font.family: root.mono
          font.pixelSize: Style.font.title
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          width: parent.width - x
          text: root.hasWeather ? Sky.conditionName(root.current.weather_code) : "No forecast"
          elide: Text.ElideRight
          color: root.ink
          font.family: root.sans
          font.pixelSize: Style.font.subtitle
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // What changes next; the mood line only when nothing does.
      Row {
        visible: root.weatherExpanded && root.next !== null
        width: parent.width
        spacing: Style.space(6)
        Text {
          id: nextIcon
          anchors.verticalCenter: parent.verticalCenter
          text: root.next ? WeatherModel.iconForOpenMeteoCode(root.next.code, false) : ""
          color: root.next && root.next.kind === "heat" ? root.warm : root.accent
          font.family: root.mono
          font.pixelSize: Style.font.body
        }
        Text {
          id: nextLabel
          width: Math.min(implicitWidth, parent.width - nextIcon.width - nextChance.width - Style.space(12))
          anchors.verticalCenter: parent.verticalCenter
          text: root.nextText(root.next)
          elide: Text.ElideRight
          color: root.ink
          font.family: root.sans
          font.pixelSize: Style.font.subtitle
        }
        Text {
          id: nextChance
          anchors.verticalCenter: parent.verticalCenter
          text: root.next && root.next.chance ? root.next.chance + "%" : ""
          color: root.accent
          font.family: root.mono
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        visible: root.weatherExpanded && !root.compact && root.hasWeather && root.next === null
        width: parent.width
        text: Sky.mood(art.kind, art.night)
        elide: Text.ElideRight
        color: root.dim
        font.family: root.sans
        font.pixelSize: Style.font.subtitle
      }

      Text {
        visible: root.statusLine !== "" && (!root.hasWeather || !!root.row.stale || (root.weatherExpanded && !root.stripVisible))
        width: parent.width
        text: root.statusLine
        elide: Text.ElideRight
        color: root.dim
        font.family: root.mono
        font.pixelSize: Style.font.caption
      }

      // Today and the next three days, in place of the H · L line.
      Item {
        visible: root.stripVisible
        width: parent.width
        height: visible ? strip.height + Style.space(10) : 0
        Rectangle { y: Style.space(4); width: parent.width; height: 1; color: root.line }
        Row {
          id: strip
          y: Style.space(10)
          width: parent.width
          Repeater {
            model: root.forecastDays
            Item {
              required property var modelData
              required property int index
              width: strip.width / Math.max(1, root.forecastDays.length)
              height: cell.implicitHeight
              Rectangle { visible: index > 0; width: 1; height: parent.height; color: root.line }
              Column {
                id: cell
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(2)
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.offset === 0 ? "Today" : modelData.name
                  color: modelData.offset === 0 ? root.ink : root.dim
                  font.family: root.mono
                  font.pixelSize: Style.font.caption
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: WeatherModel.iconForOpenMeteoCode(modelData.code, false)
                  color: root.ink
                  font.family: root.mono
                  font.pixelSize: Style.font.title
                }
                // High and low side by side, stacked when the cell is narrow.
                Grid {
                  anchors.horizontalCenter: parent.horizontalCenter
                  columns: strip.width / Math.max(1, root.forecastDays.length) >= Style.space(60) ? 2 : 1
                  columnSpacing: Style.space(3)
                  horizontalItemAlignment: Grid.AlignHCenter
                  Text { text: root.temp(modelData.hi); color: root.ink; font.family: root.mono; font.pixelSize: Style.font.caption }
                  Text { text: root.temp(modelData.lo); color: root.dim; font.family: root.mono; font.pixelSize: Style.font.caption }
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.chance !== null && modelData.chance >= 30 ? modelData.chance + "%" : " "
                  color: root.accent
                  font.family: root.mono
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.clickable
    cursorShape: Qt.PointingHandCursor
    onClicked: root.focusRequested()
  }
}
