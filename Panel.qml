import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "WeatherModel.js" as WeatherModel
import "StatusColors.js" as Palette

Panel {
  id: root
  readonly property bool darkPalette: Color.popups.background.r * 0.299 + Color.popups.background.g * 0.587 + Color.popups.background.b * 0.114 < 0.5
  moduleName: "io.github.binarysentient.worldscape"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property var worldClocks: []
  readonly property var localWeather: worldClocks.find(function(row) { return row.local }) || null
  readonly property var localCondition: localWeather && localWeather.report ? localWeather.report.current : null
  readonly property string weatherPeek: localCondition
    ? WeatherModel.iconForOpenMeteoCode(localCondition.weather_code, localCondition.is_day === 0) + " " + Math.round(localCondition.temperature_2m) + "°C"
    : ""
  property string clockError: ""
  readonly property string family: fontFamily
  readonly property bool imperial: setting("unit", "metric") === "imperial"
  readonly property int weekStart: Model.normalizedWeekStart(setting("weekStartDay", null), Qt.locale().firstDayOfWeek)
  readonly property var weekdays: Model.weekdayOrder(weekStart)
  readonly property var weeks: Model.monthGrid(viewYear, viewMonth, weekStart, Model.keyForDate(today))
  readonly property string fontFamily: Style.font.family
  readonly property color ink: Color.popups.text
  function temperature(value) {
    if (value === undefined || value === null) return "—"
    return Math.round(imperial ? Number(value) * 9 / 5 + 32 : Number(value)) + "°"
  }
  function condition(code) {
    if (code === 0) return "Clear"
    if (code === 1) return "Mostly clear"
    if (code === 2) return "Partly cloudy"
    if (code === 3) return "Overcast"
    if (code === 45 || code === 48) return "Fog"
    if (code >= 51 && code <= 57) return "Drizzle"
    if (code >= 61 && code <= 67) return "Rain"
    if (code >= 71 && code <= 77) return "Snow"
    if (code >= 80 && code <= 82) return "Rain showers"
    if (code === 85 || code === 86) return "Snow showers"
    if (code >= 95) return "Thunderstorms"
    return "Weather"
  }
  function refreshWeather() { if (!weatherProcess.running) weatherProcess.running = true }
  function refresh() {
    today = new Date()
    if (!worldProcess.running) worldProcess.running = true
  }
  function goToToday() { viewYear = today.getFullYear(); viewMonth = today.getMonth() }
  function moveMonth(delta) {
    var d = Model.stepMonth(viewYear, viewMonth, delta)
    viewYear = d.year; viewMonth = d.month
  }
  function setCenterHoverRevealSuppressed(value) {
    if (bar && typeof bar.setCenterHoverRevealSuppressed === "function")
      bar.setCenterHoverRevealSuppressed(value)
    else if (bar && "centerHoverRevealSuppressed" in bar)
      bar.centerHoverRevealSuppressed = value
  }
  function open() {
    refresh(); refreshWeather(); goToToday(); controller.show()
    Qt.callLater(function() { if (root.opened) root.setCenterHoverRevealSuppressed(true) })
  }
  function close() { setCenterHoverRevealSuppressed(false); controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function toggleWeekStart() {
    var entry = {id: moduleName}
    for (var key in settings) entry[key] = settings[key]
    entry.weekStartDay = Model.weekStartSettingName(Model.toggledWeekStart(weekStart))
    settings = entry
    if (hostWidget) hostWidget.settings = entry
    if (bar && bar.shell) bar.shell.updateEntryInline(moduleName, entry)
  }
  function switchPanel(direction) { if (bar) return bar.switchPanelFrom(hostWidget || root, direction); return false }
  onOpenedChanged: if (opened) Qt.callLater(function() { keys.forceActiveFocus() })
  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: {
      var wasCurrent = root.viewYear === root.today.getFullYear() && root.viewMonth === root.today.getMonth()
      root.today = date
      if (wasCurrent) root.goToToday()
      if (root.opened) root.refresh()
    }
  }
  Process {
    id: worldProcess
    command: ["python3", Qt.resolvedUrl("combined.py").toString().replace("file://", "")]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.worldClocks = JSON.parse(text); root.clockError = "" }
        catch (e) { root.clockError = "Could not read world clocks" }
      }
    }
  }
  Timer { interval: 15000; running: root.opened; repeat: true; onTriggered: root.refresh() }
  Process {
    id: weatherProcess
    command: ["python3", Qt.resolvedUrl("combined.py").toString().replace("file://", ""), "--weather"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { JSON.parse(text); root.refresh(); root.clockError = "" }
        catch (e) { root.clockError = "Weather update failed; showing saved data" }
      }
    }
  }
  Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshWeather() }
  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: fittedContentWidth(Style.space(1070))
    contentHeight: fittedContentHeight(Style.space(525))
    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.goToToday()
      onMoveRequested: function(dx,dy) { root.moveMonth(dx || dy) }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t.toLowerCase() === "t") root.goToToday(); else if(t.toLowerCase() === "w") root.toggleWeekStart() }
      Flickable {
        id: viewport
        anchors.fill: parent
        contentWidth: layout.width
        contentHeight: layout.height
        clip: true
        Row {
          id: layout
          width: Math.max(viewport.width, Style.space(1020))
          height: Style.space(525)
          spacing: Style.space(22)
          Column {
            width: Style.space(310)
            spacing: Style.space(14)
            Text {
              text: Qt.formatDate(root.today, "dddd, d MMMM")
              color: root.ink
              font.family: root.fontFamily
              font.pixelSize: Style.space(18)
              font.bold: true
            }
            Item {
              width: parent.width; height: Style.space(32)
              PanelActionButton {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅁"; tooltipText: "Previous month"
                foreground: root.ink; onClicked: root.moveMonth(-1)
              }
              Text {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.viewYear,root.viewMonth,1), "MMMM yyyy")
                color: root.ink; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true
              }
              PanelActionButton {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅂"; tooltipText: "Next month"
                foreground: root.ink; onClicked: root.moveMonth(1)
              }
            }
            Column {
              id: grid
              width: parent.width
              spacing: Style.space(4)
              Row {
                width: parent.width
                Repeater {
                  model: root.weekdays
                  Text {
                    required property var modelData
                    width: grid.width/7; height: Style.space(23)
                    text: ["Su","Mo","Tu","We","Th","Fr","Sa"][modelData]
                    horizontalAlignment: Text.AlignHCenter
                    color: root.ink; opacity: 0.65
                    font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall
                  }
                }
              }
              Repeater {
                model: root.weeks
                Row {
                  required property var modelData
                  Repeater {
                    model: modelData.days
                    Rectangle {
                      required property var modelData
                      width: grid.width/7; height: Style.space(31)
                      color: modelData.today ? Style.selectedFillFor(root.ink,Color.accent) : "transparent"
                      radius: Style.space(4)
                      border.width: modelData.today ? 1 : 0
                      border.color: Color.accent
                      Text {
                        anchors.centerIn: parent
                        text: parent.modelData.day
                        color: root.ink
                        opacity: parent.modelData.inMonth ? 1 : 0.35
                        font.family: root.fontFamily; font.pixelSize: Style.font.body
                        font.bold: parent.modelData.today
                      }
                    }
                  }
                }
              }
            }
            Text {
              text: "Today · T / Enter     Month · ← →"
              color: root.ink; opacity: 0.6
              font.family: root.fontFamily; font.pixelSize: Style.space(11)
              MouseArea { anchors.fill: parent; onClicked: root.goToToday() }
            }
          }
          Rectangle { width: Style.space(1); height: parent.height; color: root.ink; opacity: 0.12 }
          Column {
            width: parent.width - Style.space(355)
            spacing: Style.space(8)
            Item {
              width: parent.width; height: Style.space(24)
              Text { text: "World time"; color: root.ink; font.family: root.family; font.pixelSize: Style.space(18); font.bold: true }
              Text { x: Style.space(312); text: "Weather"; color: root.ink; font.family: root.family; font.pixelSize: Style.space(18); font.bold: true }
            }
            Repeater {
              model: root.worldClocks
              Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property var report: modelData.report
                readonly property var current: report ? report.current : null
                width: parent.width; height: Style.space(112)
                color: modelData.local ? Style.selectedFillFor(root.ink,Color.accent) : "transparent"
                radius: Style.space(5)
                border.width: modelData.local ? 1 : 0
                border.color: Color.accent
                Column {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.margins: Style.space(9)
                  width: Style.space(280)
                  spacing: Style.space(5)
                  Row {
                    width: parent.width
                    spacing: Style.space(7)
                    Text {
                      width: parent.width - clockTime.implicitWidth - periodIcon.implicitWidth - parent.spacing * 2
                      text: modelData.city + ", " + (modelData.country === "United States" ? "USA" : modelData.country === "United Kingdom" ? "UK" : modelData.country)
                      elide: Text.ElideRight
                      anchors.verticalCenter: parent.verticalCenter
                      color: modelData.local ? Color.accent : root.ink
                      font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true
                    }
                    Text {
                      id: periodIcon
                      text: modelData.periodIcon || ""
                      color: Palette.timeColor(modelData.time, root.darkPalette)
                      font.family: root.fontFamily
                      font.pixelSize: Style.space(22)
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      id: clockTime
                      text: modelData.time
                      color: Palette.timeColor(modelData.time, root.darkPalette)
                      font.family: root.fontFamily; font.pixelSize: Style.space(22); font.bold: true
                    }
                  }
                  Text {
                    text: (modelData.local ? "Local · " : "") + modelData.abbreviation + " · " + modelData.date + (modelData.local ? "" : " · " + modelData.difference)
                    width: parent.width; elide: Text.ElideRight
                    color: root.ink; opacity: 0.65
                    font.family: root.fontFamily; font.pixelSize: Style.space(11)
                  }
                }
                Column {
                  x: Style.space(312); y: Style.space(8)
                  width: parent.width - x - Style.space(8)
                  spacing: Style.space(5)
                  Row {
                    spacing: Style.space(12)
                    Text {
                      text: card.current ? WeatherModel.iconForOpenMeteoCode(card.current.weather_code, card.current.is_day === 0) : "—"
                      color: Palette.weatherColor(card.current ? card.current.weather_code : null, card.current && card.current.is_day === 0, root.darkPalette); font.family: root.family; font.pixelSize: Style.space(24)
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: root.temperature(card.current ? card.current.temperature_2m : null)
                      color: Palette.temperatureColor(card.current ? card.current.temperature_2m : null, root.darkPalette); font.family: root.family; font.pixelSize: Style.space(22); font.bold: true
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: card.current ? root.condition(card.current.weather_code) : "Unavailable"
                      color: root.ink; font.family: root.family; font.pixelSize: Style.font.bodySmall
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                  Text {
                    width: parent.width; elide: Text.ElideRight
                    text: card.modelData.stale ? "Offline · cached forecast" : card.current ? "Feels " + root.temperature(card.current.apparent_temperature) + " · Wind " + Math.round(card.current.wind_speed_10m * (root.imperial ? 0.621371 : 1)) + " · Humidity " + card.current.relative_humidity_2m + "%" : card.modelData.error
                    color: root.ink; opacity: 0.7; font.family: root.family; font.pixelSize: Style.space(11)
                  }
                  Rectangle { width: parent.width; height: 1; color: root.ink; opacity: 0.12 }
                  Row {
                    width: parent.width
                    Repeater {
                      model: card.report ? WeatherModel.openMeteoForecastDays(card.report, card.report.current.time.slice(0,10)) : []
                      Column {
                        required property var modelData
                        width: parent.width / 3
                        spacing: Style.space(4)
                        Text {
                          text: WeatherModel.dayName(modelData.date).slice(0,3)
                          color: root.ink; opacity: 0.65; font.family: root.family; font.pixelSize: Style.font.bodySmall
                        }
                        Text {
                          text: WeatherModel.dayIcon(modelData) + " " + WeatherModel.bareTempForDay(modelData,"max",root.imperial) + " / " + WeatherModel.bareTempForDay(modelData,"min",root.imperial)
                          color: root.ink; font.family: root.family; font.pixelSize: Style.space(11)
                        }
                      }
                    }
                  }

                }
                Rectangle {
                  visible: card.index < root.worldClocks.length - 1
                  anchors.left: parent.left; anchors.right: parent.right
                  y: parent.height + Style.space(4)
                  height: 1; color: root.ink; opacity: 0.18
                }
              }
            }
            Text {
              text: root.clockError || ("Open-Meteo · " + (root.imperial ? "°F · mph" : "°C · km/h") + " · Weather every 15 min" + (weatherProcess.running ? " · Updating…" : ""))
              color: root.ink; opacity: 0.65; font.family: root.family; font.pixelSize: Style.space(11)
            }
          }
        }
      }
    }
  }
}
