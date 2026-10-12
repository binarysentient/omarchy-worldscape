import QtQuick
import qs.Commons
import qs.Ui
import "Sky.js" as Sky
import "Forecast.js" as Forecast
import "WeatherModel.js" as WeatherModel

// One city up close: a large window with its sill, the next 24 hours as a
// temperature line over rain-chance bars, and the week either as range bars
// on one shared scale or as small windows drawn with each day's weather.
Item {
  id: root

  property var row: ({})
  property real utcMs: Date.now()
  property int offsetMinutes: 0
  property bool h24: true
  property bool imperial: false
  property bool animate: false
  property string style: "glass"
  property var pal: ({})
  property string sans: "sans-serif"
  property color ink: Color.popups.text
  property color dim: ink
  property color line: dim
  property color surface: "transparent"
  property color accent: Color.accent
  property color warm: accent
  property string weekView: "range"   // range | panes

  signal back()
  signal weekViewPicked(string view)

  readonly property string mono: Style.font.family
  readonly property var report: row && row.report ? row.report : null
  readonly property var current: report && report.current ? report.current : null
  readonly property var dayList: Forecast.days(report, Forecast.localKeys(utcMs, offsetMinutes).date, 7)
  readonly property var hourList: Forecast.hours(report, utcMs, offsetMinutes, 24)
  readonly property bool wide: width >= Style.space(720)
  readonly property real leftWidth: wide ? Math.round(width * 0.37) : width
  readonly property real gap: Style.space(22)
  readonly property real weekLo: { var m = Infinity; for (var i = 0; i < dayList.length; i++) if (dayList[i].lo !== null) m = Math.min(m, dayList[i].lo); return isFinite(m) ? m : 0 }
  readonly property real weekHi: { var m = -Infinity; for (var i = 0; i < dayList.length; i++) if (dayList[i].hi !== null) m = Math.max(m, dayList[i].hi); return isFinite(m) ? m : 1 }
  readonly property real rainPeak: { var m = 0; for (var i = 0; i < hourList.length; i++) m = Math.max(m, hourList[i].chance || 0); return m }

  function temp(c) {
    if (c === undefined || c === null || !isFinite(Number(c))) return "—"
    return Math.round(imperial ? Number(c) * 9 / 5 + 32 : Number(c)) + "°"
  }
  function hourText(h) { return h24 ? (h < 10 ? "0" : "") + h + ":00" : (h % 12 || 12) + (h < 12 ? " AM" : " PM") }
  // An instant that reads 13:30 on `dateKey` in this city, for the panes.
  function middayUtc(dateKey) {
    var p = String(dateKey).split("-")
    return Date.UTC(Number(p[0]), Number(p[1]) - 1, Number(p[2]), 13, 30) - offsetMinutes * 60000
  }

  implicitHeight: wide ? Math.max(left.implicitHeight, right.implicitHeight) : left.implicitHeight + gap + right.implicitHeight

  Column {
    id: left
    width: root.leftWidth
    spacing: Style.space(10)

    Button {
      text: "← All cities · Esc"
      foreground: root.ink; accent: root.accent; bordered: true
      onClicked: root.back()
    }
    CityCard {
      width: parent.width
      row: root.row
      utcMs: root.utcMs
      offsetMinutes: root.offsetMinutes
      windowHeight: Style.space(root.wide ? 300 : 220)
      showStrip: false
      h24: root.h24
      imperial: root.imperial
      animate: root.animate
      style: root.style
      pal: root.pal
      sans: root.sans
      ink: root.ink
      dim: root.dim
      line: root.line
      warm: root.warm
    }
  }

  Column {
    id: right
    x: root.wide ? root.leftWidth + root.gap : 0
    y: root.wide ? 0 : left.implicitHeight + root.gap
    width: root.width - x
    spacing: Style.space(10)

    Item {
      width: parent.width
      height: Style.space(22)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "NEXT 24 HOURS"
        color: root.dim
        font.family: root.mono
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.hourList.length === 0 ? "No hourly forecast yet" : root.rainPeak >= 30 ? "Rain up to " + root.rainPeak + "%" : "No rain expected"
        color: root.rainPeak >= 30 ? root.accent : root.dim
        font.family: root.mono
        font.pixelSize: Style.font.caption
      }
    }

    Canvas {
      id: chart
      visible: root.hourList.length >= 2
      width: parent.width
      height: visible ? Style.space(150) : 0
      readonly property string paintKey: [width, height, JSON.stringify(root.hourList), root.imperial, root.h24,
        Sky.hex(root.ink), Sky.hex(root.dim), Sky.hex(root.line), Sky.hex(root.accent), Sky.hex(root.warm)].join("|")
      onPaintKeyChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var h = root.hourList, n = h.length
        if (n < 2 || width <= 0) return
        var pad = Style.space(12), top = Style.space(22), bottom = height - Style.space(52)
        var barBase = height - Style.space(22), barMax = Style.space(26)
        var lo = Infinity, hi = -Infinity
        for (var i = 0; i < n; i++) { lo = Math.min(lo, h[i].temp); hi = Math.max(hi, h[i].temp) }
        var span = Math.max(1, hi - lo)
        function X(i) { return pad + i * (width - pad * 2) / (n - 1) }
        function Y(t) { return bottom - (t - lo) / span * (bottom - top) }
        var px = Style.font.caption
        ctx.font = px + "px \"" + root.mono + "\""
        ctx.textAlign = "center"
        // Hour guides every six hours.
        ctx.strokeStyle = Sky.hex(root.line); ctx.lineWidth = 1
        for (i = 0; i < n; i += 6) {
          ctx.beginPath(); ctx.moveTo(Math.round(X(i)) + 0.5, top - Style.space(8)); ctx.lineTo(Math.round(X(i)) + 0.5, barBase); ctx.stroke()
          ctx.fillStyle = Sky.hex(root.dim)
          ctx.fillText(i === 0 ? "Now" : root.hourText(h[i].hour), X(i), height - Style.space(4))
        }
        // Rain chance bars along the bottom.
        ctx.fillStyle = Sky.hex(root.accent); ctx.globalAlpha = 0.7
        var bw = Math.max(2, (width - pad * 2) / n * 0.5)
        for (i = 0; i < n; i++) {
          var c = h[i].chance || 0
          if (c < 10) continue
          var bh = c / 100 * barMax
          ctx.fillRect(X(i) - bw / 2, barBase - bh, bw, bh)
        }
        // Temperature area and line.
        ctx.globalAlpha = 0.12; ctx.fillStyle = Sky.hex(root.warm)
        ctx.beginPath(); ctx.moveTo(X(0), bottom + Style.space(6))
        for (i = 0; i < n; i++) ctx.lineTo(X(i), Y(h[i].temp))
        ctx.lineTo(X(n - 1), bottom + Style.space(6)); ctx.closePath(); ctx.fill()
        ctx.globalAlpha = 1; ctx.strokeStyle = Sky.hex(root.warm); ctx.lineWidth = Math.max(1.5, Style.space(2))
        ctx.beginPath()
        for (i = 0; i < n; i++) { if (i === 0) ctx.moveTo(X(i), Y(h[i].temp)); else ctx.lineTo(X(i), Y(h[i].temp)) }
        ctx.stroke()
        // Label the warmest and coolest hours.
        var iHi = 0, iLo = 0
        for (i = 1; i < n; i++) { if (h[i].temp > h[iHi].temp) iHi = i; if (h[i].temp < h[iLo].temp) iLo = i }
        ctx.fillStyle = Sky.hex(root.ink)
        ctx.textAlign = iHi === 0 ? "left" : iHi === n - 1 ? "right" : "center"
        ctx.fillText(root.temp(h[iHi].temp), X(iHi), Y(h[iHi].temp) - Style.space(7))
        if (iLo !== iHi) {
          ctx.textAlign = iLo === 0 ? "left" : iLo === n - 1 ? "right" : "center"
          ctx.fillText(root.temp(h[iLo].temp), X(iLo), Y(h[iLo].temp) + px + Style.space(5))
        }
      }
    }

    Item {
      width: parent.width
      height: Style.space(30)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.dayList.length + " DAYS"
        color: root.dim
        font.family: root.mono
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }
      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)
        Button {
          text: "Range"
          foreground: root.ink; accent: root.accent; bordered: root.weekView === "range"
          onClicked: root.weekViewPicked("range")
        }
        Button {
          text: "Panes"
          foreground: root.ink; accent: root.accent; bordered: root.weekView === "panes"
          onClicked: root.weekViewPicked("panes")
        }
      }
    }

    Text {
      visible: root.dayList.length === 0
      text: "No daily forecast yet"
      color: root.dim
      font.family: root.mono
      font.pixelSize: Style.font.caption
    }

    // Range: one row per day, bars on the week's shared scale.
    Column {
      visible: root.weekView !== "panes" && root.dayList.length > 0
      width: parent.width
      Repeater {
        model: root.dayList
        Item {
          id: dayRow
          required property var modelData
          required property int index
          width: parent.width
          height: Style.space(30)
          readonly property real span: Math.max(1, root.weekHi - root.weekLo)
          Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.line }
          Text {
            id: dn
            width: Style.space(62)
            anchors.verticalCenter: parent.verticalCenter
            text: dayRow.modelData.offset === 0 ? "Today" : dayRow.modelData.name + " " + Number(dayRow.modelData.key.slice(8, 10))
            color: dayRow.modelData.offset === 0 ? root.ink : root.dim
            font.family: root.mono
            font.pixelSize: Style.font.bodySmall
          }
          Text {
            id: di
            x: dn.width
            width: Style.space(24)
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherModel.iconForOpenMeteoCode(dayRow.modelData.code, false)
            color: root.ink
            font.family: root.mono
            font.pixelSize: Style.font.title
          }
          Text {
            id: dp
            x: di.x + di.width
            width: Style.space(38)
            anchors.verticalCenter: parent.verticalCenter
            text: dayRow.modelData.chance !== null && dayRow.modelData.chance >= 30 ? dayRow.modelData.chance + "%" : ""
            color: root.accent
            font.family: root.mono
            font.pixelSize: Style.font.caption
          }
          Text {
            id: dlo
            x: dp.x + dp.width
            width: Style.space(34)
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.temp(dayRow.modelData.lo)
            color: root.dim
            font.family: root.mono
            font.pixelSize: Style.font.bodySmall
          }
          Rectangle {
            id: track
            x: dlo.x + dlo.width + Style.space(10)
            width: parent.width - x - Style.space(44)
            height: Style.space(6); radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.surface
            Rectangle {
              visible: dayRow.modelData.lo !== null && dayRow.modelData.hi !== null
              x: (dayRow.modelData.lo - root.weekLo) / dayRow.span * track.width
              width: Math.max(height, (dayRow.modelData.hi - dayRow.modelData.lo) / dayRow.span * track.width)
              height: parent.height; radius: parent.radius
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.accent }
                GradientStop { position: 1; color: root.warm }
              }
            }
            Rectangle {
              visible: dayRow.modelData.offset === 0 && dayRow.modelData.lo !== null && dayRow.modelData.hi !== null && root.current !== null && root.current.temperature_2m !== undefined && root.current.temperature_2m !== null
              readonly property real t: visible ? Math.max(dayRow.modelData.lo, Math.min(dayRow.modelData.hi, Number(root.current.temperature_2m))) : 0
              width: Style.space(10); height: width; radius: width / 2
              x: (t - root.weekLo) / dayRow.span * track.width - width / 2
              anchors.verticalCenter: parent.verticalCenter
              color: Color.popups.background
              border.width: Math.max(1, Style.space(2))
              border.color: root.ink
            }
          }
          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.temp(dayRow.modelData.hi)
            color: root.ink
            font.family: root.mono
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }

    // Panes: the week as small windows at midday, each with its weather.
    Grid {
      id: panes
      visible: root.weekView === "panes" && root.dayList.length > 0
      width: parent.width
      columns: width >= Style.space(480) ? Math.max(1, root.dayList.length) : 4
      columnSpacing: Style.space(8)
      rowSpacing: Style.space(10)
      readonly property real paneWidth: (width - columnSpacing * (columns - 1)) / columns
      Repeater {
        model: panes.visible ? root.dayList : []
        Column {
          required property var modelData
          required property int index
          width: panes.paneWidth
          spacing: Style.space(3)
          CityWindow {
            width: parent.width
            height: Style.space(92)
            city: root.row.city || ""
            region: root.row.region || ""
            latitude: root.row.latitude
            longitude: root.row.longitude
            utcMs: root.middayUtc(modelData.key)
            offsetMinutes: root.offsetMinutes
            weatherCode: modelData.code
            style: root.style
            compact: true
            animate: false
            pal: root.pal
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.offset === 0 ? "Today" : modelData.name
            color: modelData.offset === 0 ? root.ink : root.dim
            font.family: root.mono
            font.pixelSize: Style.font.caption
          }
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(3)
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
