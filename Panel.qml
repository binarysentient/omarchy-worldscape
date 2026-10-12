import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "WeatherModel.js" as WeatherModel
import "Sky.js" as Sky
import "Forecast.js" as Forecast
import "ThemeMatch.js" as ThemeMatch

// Windows on the world: the calendar and home weather on the left; on the
// right a day ribbon placing every city on one 24-hour band, then a card per
// city reading time, window, weather. Clicking a window (or
// pressing 1–4) opens that city's focus view with hourly and weekly detail.
Panel {
  id: root
  moduleName: "io.github.binarysentient.worldscape"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property date today: new Date()
  property real nowMs: Date.now()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property var worldClocks: []
  property string clockError: ""
  property bool customizing: false
  property int focusIndex: -1          // city in the focus view, -1 for all
  property string weekView: "range"    // focus view: range | panes
  property string selectedDayKey: ""   // calendar day shown in the home card

  // ---- Shared preferences (shell.json entry). Survive style changes.
  readonly property string styleSetting: ThemeMatch.normalizedStyle(setting("style", "auto"))
  readonly property bool motion: setting("motion", "animated") !== "quiet"
  readonly property bool compactClocks: setting("clockLayout", "expanded") === "compact"
  readonly property bool weatherExpanded: setting("weatherLayout", "expanded") !== "compact"
  readonly property bool showCalendar: setting("calendar", "show") !== "hide"
  readonly property bool compactCalendar: setting("calendarLayout", "expanded") === "compact"
  readonly property bool h24: String(setting("hours", "24")) !== "12"
  readonly property bool imperial: setting("unit", "metric") === "imperial"
  readonly property bool barWeather: setting("barWeather", true) !== false && setting("barWeather", true) !== "false"
  readonly property int weekStart: Model.normalizedWeekStart(setting("weekStartDay", null), Qt.locale().firstDayOfWeek)
  readonly property var weekdays: Model.weekdayOrder(weekStart)
  readonly property var weeks: Model.monthGrid(viewYear, viewMonth, weekStart, Model.keyForDate(today))
  readonly property var settingKeys: ["style", "motion", "clockLayout", "weatherLayout", "calendar", "calendarLayout", "hours", "unit", "weekStartDay", "format", "barWeather"]

  // ---- Appearance. The palette is always the live theme; Auto picks the
  //      window style from it (ThemeMatch.js). Rebinds on theme switches.
  readonly property var appearance: ThemeMatch.resolve(Sky.hex(Color.background), Sky.hex(Color.foreground), Sky.hex(Color.accent), styleSetting)
  readonly property string windowStyle: appearance.style
  readonly property string autoStyleName: ThemeMatch.resolve(Sky.hex(Color.background), Sky.hex(Color.foreground), Sky.hex(Color.accent), "auto").styleName
  readonly property string appearanceNote: !appearance.auto
    ? appearance.styleName + " windows in your desktop palette. Auto would choose " + autoStyleName + "."
    : appearance.exact
      ? "Auto: " + appearance.styleName + " windows suit " + appearance.themeName + ". Follows your theme when it changes."
      : "Auto: your own palette, closest to " + appearance.relative + " (" + appearance.relativeScore + "% similar), so " + appearance.styleName + " windows."
  readonly property color ink: Color.popups.text
  readonly property color surfaceColor: Color.popups.background
  readonly property string bgHex: Sky.hex(Color.popups.background)
  readonly property string inkHex: Sky.hex(Color.popups.text)
  readonly property color dim: Sky.mix(inkHex, bgHex, 0.36)
  readonly property color raised: Sky.mix(bgHex, inkHex, 0.07)
  readonly property var pal: ({ bg: bgHex, fg: inkHex, accent: Sky.hex(Color.accent), warm: appearance.warm, green: appearance.green })
  readonly property color line: Sky.mix(bgHex, inkHex, 0.14)
  readonly property color warm: appearance.warm
  // One type system for every window style: the desktop sans for names, time
  // and prose, the shell's mono for data and captions. Styles change the art.
  readonly property string sans: "sans-serif"

  // ---- Home city and what the bar peeks at.
  readonly property var homeRow: worldClocks.find(function(row) { return row && row.local }) || worldClocks[0] || null
  readonly property var localCondition: homeRow && homeRow.report && homeRow.report.current ? homeRow.report.current : null
  readonly property bool hasHomeWeather: localCondition !== null && localCondition.temperature_2m !== undefined && localCondition.temperature_2m !== null
  readonly property string weatherPeek: barWeather && hasHomeWeather
    ? WeatherModel.iconForOpenMeteoCode(localCondition.weather_code, localCondition.is_day === 0) + " " + temperature(localCondition.temperature_2m)
    : ""
  readonly property int homeOffset: homeRow ? Sky.rowOffset(homeRow, nowMs) : -new Date(nowMs).getTimezoneOffset()
  readonly property var homeSun: homeRow ? Sky.solarDay(homeRow.latitude, homeRow.longitude, nowMs, homeOffset) : Sky.solarDay(null, null, nowMs, homeOffset)
  readonly property real homeHour: Sky.cityTime(nowMs, homeOffset, true).hour
  readonly property string homeKind: Sky.weatherKind(hasHomeWeather ? localCondition.weather_code : null)
  // ---- Home forecast: calendar glyphs and the home card.
  readonly property var homeReport: homeRow && homeRow.report ? homeRow.report : null
  readonly property var homeDays: Forecast.days(homeReport, Forecast.localKeys(nowMs, homeOffset).date, 7)
  readonly property var homeNext: hasHomeWeather ? Forecast.nextChange(homeReport, nowMs, homeOffset) : null
  readonly property var calendarForecast: {
    var map = {}
    for (var i = 0; i < homeDays.length; i++) {
      var d = homeDays[i]
      map[d.key] = { glyph: WeatherModel.iconForOpenMeteoCode(d.code, false), wet: d.chance !== null && d.chance >= 30 }
    }
    return map
  }
  function homeDay(offset) {
    for (var i = 0; i < homeDays.length; i++) if (homeDays[i].offset === offset) return homeDays[i]
    return null
  }
  readonly property var pickedDay: {
    if (!selectedDayKey) return null
    for (var i = 0; i < homeDays.length; i++)
      if (homeDays[i].key === selectedDayKey && homeDays[i].offset > 0) return homeDays[i]
    return null
  }
  readonly property string moodTitle: {
    if (!homeRow) return ""
    if (pickedDay) return Forecast.fullDayName(pickedDay.key) + " · " + Sky.conditionName(pickedDay.code)
    return hasHomeWeather ? Sky.conditionName(localCondition.weather_code) + ", " + temperature(localCondition.temperature_2m) : "Weather unavailable"
  }
  readonly property string moodNext: {
    if (pickedDay) return pickedDay.chance !== null && pickedDay.chance >= 30 ? pickedDay.chance + "% chance of rain" : ""
    if (!weatherExpanded || !homeNext) return ""
    var n = homeNext, at = hourOnly(n.hour)
    var text = n.kind === "wet" ? n.label + " from ~" + at
      : n.kind === "dry" ? "Clearing by ~" + at
      : n.kind === "heat" ? "Up to " + temperature(n.temp) + " by " + at
      : "Frost by ~" + at
    return text + (n.chance ? " · " + n.chance + "%" : "")
  }
  readonly property string moodDetail: {
    if (!homeRow) return ""
    var parts = []
    if (pickedDay) {
      parts.push(degrees(pickedDay.hi) + " / " + degrees(pickedDay.lo))
      if (pickedDay.sunrise) parts.push("Sunrise " + clockLabel(pickedDay.sunrise))
      if (pickedDay.sunset) parts.push("Sunset " + clockLabel(pickedDay.sunset))
      return parts.join(" · ")
    }
    if (!homeSun.polar) {
      var night = homeHour < homeSun.sunrise || homeHour > homeSun.sunset
      var todaySun = homeDay(0)
      var tomorrow = homeDay(1)
      var exact = night ? (homeHour > homeSun.sunset ? tomorrow : todaySun) : todaySun
      var exactTime = exact ? (night ? exact.sunrise : exact.sunset) : ""
      parts.push((night ? "Sunrise " : "Sunset ") + (exactTime ? clockLabel(exactTime) : hourLabel(night ? homeSun.sunrise : homeSun.sunset)))
    }
    var next = homeDay(1)
    if (next) parts.push("Tomorrow " + degrees(next.hi) + " / " + degrees(next.lo))
    return parts.join("\n")
  }
  readonly property var ribbonCities: worldClocks.map(function(row) {
    var c = Sky.cityTime(nowMs, Sky.rowOffset(row, nowMs), h24)
    return { name: row.city, local: !!row.local, hour: c.hour, time: c.text + (c.suffix ? " " + c.suffix : "") }
  })
  readonly property string weatherStatus: {
    if (clockError) return clockError
    if (weatherProcess.running) return "Updating weather…"
    var newest = 0, stale = false, missing = false
    for (var i = 0; i < worldClocks.length; i++) {
      var r = worldClocks[i]
      if (r.updated) newest = Math.max(newest, Number(r.updated) || 0)
      if (r.stale) stale = true
      if (!r.report) missing = true
    }
    if (stale) return "Offline · showing saved forecast"
    if (missing && newest === 0) return "Weather unavailable · retrying"
    return newest > 0 ? "Updated " + hourLabel(new Date(newest * 1000).getHours() + new Date(newest * 1000).getMinutes() / 60) : ""
  }

  function temperature(value) {
    if (value === undefined || value === null || !isFinite(Number(value))) return "—"
    return Math.round(imperial ? Number(value) * 9 / 5 + 32 : Number(value)) + "°" + (imperial ? "F" : "C")
  }
  function degrees(value) {
    if (value === undefined || value === null || !isFinite(Number(value))) return "—"
    return Math.round(imperial ? Number(value) * 9 / 5 + 32 : Number(value)) + "°"
  }
  function hourOnly(h) { return h24 ? (h < 10 ? "0" : "") + h + ":00" : (h % 12 || 12) + (h < 12 ? " AM" : " PM") }
  // "HH:MM" from Open-Meteo, shown in the user's hour cycle.
  function clockLabel(hhmm) {
    var p = String(hhmm).split(":")
    return hourLabel(Number(p[0]) + Number(p[1]) / 60)
  }
  function focusCity(index) {
    if (index >= 0 && index < worldClocks.length) { customizing = false; focusIndex = index; viewport.contentY = 0 }
  }
  function pickDay(key) { selectedDayKey = selectedDayKey === key ? "" : key }
  function hourLabel(h) {
    var total = Math.round(h * 60), hh = Math.floor(total / 60) % 24, mm = total % 60
    var m = (mm < 10 ? "0" : "") + mm
    return h24 ? ((hh < 10 ? "0" : "") + hh + ":" + m) : ((hh % 12 || 12) + ":" + m + (hh < 12 ? " AM" : " PM"))
  }

  // ---- Bar formats offered in Customize; right-click still walks the full ring.
  readonly property var barPresets: ({ day: ["dddd HH:mm", "dddd h:mm AP"], date: ["ddd d MMM HH:mm", "ddd d MMM h:mm AP"], time: ["HH:mm", "h:mm AP"] })
  readonly property string barPreset: {
    var current = String(setting("format", "dddd HH:mm"))
    for (var key in barPresets) if (barPresets[key].indexOf(current) >= 0) return key
    return ""
  }
  function barFormat(preset) { return (barPresets[preset] || barPresets.day)[h24 ? 0 : 1] }

  // ---- Settings persistence: one merged entry written back to shell.json.
  function commitSettings(entry) {
    settings = entry
    if (hostWidget) hostWidget.settings = entry
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function") bar.shell.updateEntryInline(moduleName, entry)
  }
  function saveSettings(patch) {
    var entry = { id: moduleName }
    for (var key in settings) if (key !== "id") entry[key] = settings[key]
    for (var k in patch) entry[k] = patch[k]
    commitSettings(entry)
  }
  function resetSettings() {
    var entry = { id: moduleName }
    for (var key in settings) if (key !== "id" && settingKeys.indexOf(key) < 0) entry[key] = settings[key]
    commitSettings(entry)
  }
  function setHourCycle(is24) {
    var patch = { hours: is24 ? "24" : "12" }
    if (barPreset !== "") patch.format = barPresets[barPreset][is24 ? 0 : 1]
    saveSettings(patch)
  }
  function toggleWeekStart() {
    saveSettings({ weekStartDay: Model.weekStartSettingName(Model.toggledWeekStart(weekStart)) })
  }

  // ---- Data and lifecycle. The clock path never waits on the network.
  function refreshWeather() { if (!weatherProcess.running) weatherProcess.running = true }
  function refresh() {
    today = new Date()
    nowMs = Date.now()
    if (!worldProcess.running) worldProcess.running = true
  }
  function goToToday() { viewYear = today.getFullYear(); viewMonth = today.getMonth(); selectedDayKey = "" }
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
    customizing = false
    focusIndex = -1
    refresh(); refreshWeather(); goToToday(); controller.show()
    Qt.callLater(function() { if (root.opened) root.setCenterHoverRevealSuppressed(true) })
  }
  function openCustomize() { if (!opened) open(); customizing = true }
  onCustomizingChanged: {
    viewport.contentY = 0
    if (customizing) Qt.callLater(customizeView.begin)
  }
  // Keep the keyboard cursor's row on screen when the sheet overflows.
  function ensureVisible(item) {
    if (!item || viewport.height <= 0) return
    var margin = Style.space(8)
    var top = item.mapToItem(body, 0, 0).y
    var bottom = top + item.height
    var maxY = Math.max(0, viewport.contentHeight - viewport.height)
    if (top - margin < viewport.contentY) viewport.contentY = Math.max(0, top - margin)
    else if (bottom + margin > viewport.contentY + viewport.height)
      viewport.contentY = Math.min(maxY, bottom + margin - viewport.height)
  }
  function close() { setCenterHoverRevealSuppressed(false); controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function switchPanel(direction) { if (bar) return bar.switchPanelFrom(hostWidget || root, direction); return false }
  onOpenedChanged: if (opened) Qt.callLater(function() { keys.forceActiveFocus() })

  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: {
      var wasCurrent = root.viewYear === root.today.getFullYear() && root.viewMonth === root.today.getMonth()
      root.today = date
      root.nowMs = date.getTime()
      // Follow the month without clearing a picked forecast day.
      if (wasCurrent) { root.viewYear = date.getFullYear(); root.viewMonth = date.getMonth() }
      if (root.opened) root.refresh()
    }
  }
  Process {
    id: worldProcess
    command: ["python3", Qt.resolvedUrl("combined.py").toString().replace("file://", "")]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var rows = JSON.parse(text)
          if (!Array.isArray(rows) || rows.length === 0) throw new Error("empty")
          root.worldClocks = rows.filter(function(row) { return row && typeof row === "object" })
          root.clockError = ""
        } catch (e) {
          // Keep whatever was showing; a bad read must not blank the panel.
          root.clockError = root.worldClocks.length ? "" : "Could not read world clocks"
        }
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
    contentWidth: fittedContentWidth(Style.space(root.showCalendar ? 1080 : 840))
    contentHeight: fittedContentHeight(body.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      // While Customize is showing, navigation keys drive its cursor;
      // otherwise they keep their calendar/panel meaning.
      onCloseRequested: {
        if (root.customizing) root.customizing = false
        else if (root.focusIndex >= 0) root.focusIndex = -1
        else root.close()
      }
      onActivateRequested: { if (root.customizing) customizeView.activate(); else root.goToToday() }
      onMoveRequested: function(dx, dy) {
        if (root.customizing) customizeView.move(dx, dy)
        else root.moveMonth(dx || dy)
      }
      onTabRequested: function(direction) {
        if (root.customizing) customizeView.tab(direction)
        else root.switchPanel(direction)
      }
      onTextKey: function(t) {
        var k = t.toLowerCase()
        if (k === "c") root.customizing = !root.customizing
        else if (root.customizing) return
        else if (k === "t") root.goToToday()
        else if (k === "w") root.toggleWeekStart()
        else if (k >= "1" && k <= "9") root.focusCity(Number(k) - 1)
      }

      Flickable {
        id: viewport
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
          id: body
          width: viewport.width
          readonly property real gap: Style.space(22)
          readonly property bool wide: width >= Style.space(780)
          readonly property bool side: root.showCalendar && wide
          readonly property real calendarWidth: side ? Style.space(232) : Math.min(width, Style.space(360))
          implicitHeight: side ? Math.max(calendar.implicitHeight, world.implicitHeight)
            : (root.showCalendar ? calendar.implicitHeight + gap : 0) + world.implicitHeight
          height: implicitHeight

          CalendarCard {
            id: calendar
            visible: root.showCalendar
            x: 0; y: 0
            width: body.calendarWidth
            today: root.today
            viewYear: root.viewYear
            viewMonth: root.viewMonth
            weeks: root.weeks
            weekdays: root.weekdays
            expanded: !root.compactCalendar
            moodTitle: root.moodTitle
            moodNext: root.moodNext
            moodDetail: root.moodDetail
            moodPicked: root.pickedDay !== null
            forecast: root.calendarForecast
            selectedKey: root.selectedDayKey
            sans: root.sans
            ink: root.ink
            dim: root.dim
            surface: root.raised
            todayText: root.surfaceColor
            onPreviousMonth: root.moveMonth(-1)
            onNextMonth: root.moveMonth(1)
            onGoToday: root.goToToday()
            onPickDay: function(key) { root.pickDay(key) }
          }

          Rectangle {
            visible: body.side
            x: body.calendarWidth + body.gap / 2
            width: 1; height: body.height
            color: root.ink; opacity: 0.1
          }

          Column {
            id: world
            x: body.side ? body.calendarWidth + body.gap : 0
            y: body.side || !root.showCalendar ? 0 : calendar.implicitHeight + body.gap
            width: body.width - x
            spacing: Style.space(12)

            Item {
              visible: !root.customizing
              width: parent.width
              height: Style.space(26)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - styleNote.width - Style.space(12)
                elide: Text.ElideRight
                text: root.focusIndex >= 0 && root.worldClocks[root.focusIndex] ? root.worldClocks[root.focusIndex].city : "World"
                color: root.ink
                font.family: root.sans
                font.pixelSize: Style.space(20)
                font.weight: Font.Medium
              }
              Row {
                id: styleNote
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(6)
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: (root.appearance.auto ? "Auto · " : "") + root.appearance.styleName
                  color: root.dim
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                }
                PanelActionButton {
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: "󰒓"
                  tooltipText: "Customize (C)"
                  foreground: root.ink
                  onClicked: root.customizing = true
                }
              }
            }

            // The day band sits with the clocks: every city's hour first.
            DayRibbon {
              visible: !root.customizing && root.worldClocks.length > 0
              width: parent.width
              cities: root.ribbonCities
              sun: root.homeSun
              style: root.windowStyle
              pal: root.pal
              ink: root.ink
              dim: root.dim
              surface: root.surfaceColor
            }

            Grid {
              id: cities
              visible: !root.customizing && root.focusIndex < 0
              width: parent.width
              columns: width >= Style.space(600) ? Math.max(1, Math.min(4, root.worldClocks.length)) : 2
              columnSpacing: Style.space(14)
              rowSpacing: Style.space(16)
              readonly property real cardWidth: (width - columnSpacing * (columns - 1)) / columns

              Repeater {
                model: root.worldClocks
                CityCard {
                  required property var modelData
                  required property int index
                  width: cities.cardWidth
                  row: modelData
                  utcMs: root.nowMs
                  offsetMinutes: Sky.rowOffset(modelData, root.nowMs)
                  compact: root.compactClocks
                  weatherExpanded: root.weatherExpanded
                  clickable: true
                  onFocusRequested: root.focusCity(index)
                  h24: root.h24
                  imperial: root.imperial
                  animate: root.motion && root.opened && !root.customizing
                  style: root.windowStyle
                  pal: root.pal
                  sans: root.sans
                  ink: root.ink
                  dim: root.dim
                  line: root.line
                  warm: root.warm
                }
              }
            }

            CityFocus {
              visible: !root.customizing && root.focusIndex >= 0 && root.focusIndex < root.worldClocks.length
              width: parent.width
              height: visible ? implicitHeight : 0
              row: visible ? root.worldClocks[root.focusIndex] : ({})
              utcMs: root.nowMs
              offsetMinutes: visible ? Sky.rowOffset(row, root.nowMs) : 0
              h24: root.h24
              imperial: root.imperial
              animate: root.motion && root.opened && visible
              style: root.windowStyle
              pal: root.pal
              sans: root.sans
              ink: root.ink
              dim: root.dim
              line: root.line
              surface: root.raised
              warm: root.warm
              weekView: root.weekView
              onBack: root.focusIndex = -1
              onWeekViewPicked: function(view) { root.weekView = view }
            }

            Text {
              visible: !root.customizing && root.worldClocks.length === 0
              text: root.clockError || "Reading clocks…"
              color: root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }

            Item {
              visible: !root.customizing
              width: parent.width
              height: footLeft.implicitHeight
              Text {
                id: footLeft
                width: parent.width - footRight.implicitWidth - Style.space(12)
                elide: Text.ElideRight
                text: "Open-Meteo · " + (root.imperial ? "°F · mph" : "°C · km/h") + (root.weatherStatus ? " · " + root.weatherStatus : "")
                color: root.dim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
              Text {
                id: footRight
                anchors.right: parent.right
                text: root.focusIndex >= 0 ? "C customize · Esc back" : "1–" + Math.min(9, root.worldClocks.length) + " city · C customize · Esc close"
                color: root.dim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }

            CustomizeView {
              id: customizeView
              visible: root.customizing
              onCursorMoved: function(item) { Qt.callLater(root.ensureVisible, item) }
              width: parent.width
              panel: root
              ink: root.ink
              dim: root.dim
              onDone: root.customizing = false
            }
          }
        }
      }
    }
  }
}
