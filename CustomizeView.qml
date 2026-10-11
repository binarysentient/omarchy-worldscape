import QtQuick
import qs.Commons
import qs.Ui

// The small Customize sheet: everyday choices only. Every choice is saved in
// this widget's shell.json entry and is shared by all window styles.
//
// Keyboard model: a cursor of (cursorRow, cursorCol). Row 0 holds the Reset
// and Done buttons; rows 1… are the Choice rows in visual order. Up/Down move
// between rows, Left/Right between options, Enter/Space apply, Tab/Shift+Tab
// walk rows with wrap-around. Panel.qml routes keys here while customizing.
Column {
  id: root

  required property var panel
  property color ink: Color.popups.text
  property color dim: ink
  property color accent: Color.accent

  property int cursorRow: 1
  property int cursorCol: 0
  readonly property var rows: [actions, styleRow, motionRow, clocksRow, timeRow, unitRow, calendarRow, weekRow, barTimeRow, barWeatherRow]

  signal done()
  // The item under the cursor, so the panel can scroll it into view.
  signal cursorMoved(Item item)

  spacing: Style.space(4)

  readonly property var sample: new Date(2026, 0, 1, 15, 42)

  function optionCount(r) { return r === 0 ? 2 : rows[r].options.length }
  function focusRow(r) {
    cursorRow = Math.max(0, Math.min(rows.length - 1, r))
    cursorCol = cursorRow === 0 ? 1 : Math.max(0, rows[cursorRow].chosenIndex)
    cursorMoved(rows[cursorRow])
  }
  function begin() { focusRow(1) }
  function move(dx, dy) {
    if (dy !== 0) { focusRow(cursorRow + dy); return }
    cursorCol = Math.max(0, Math.min(optionCount(cursorRow) - 1, cursorCol + dx))
    cursorMoved(rows[cursorRow])
  }
  function tab(direction) { focusRow((cursorRow + direction + rows.length) % rows.length) }
  function activate() {
    if (cursorRow === 0) {
      if (cursorCol === 0) panel.resetSettings()
      else done()
      return
    }
    rows[cursorRow].pickAt(cursorCol)
  }

  Item {
    id: actions
    width: parent.width
    height: Style.space(32)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "Customize"
      color: root.ink
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
    }
    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(6)
      Button {
        text: "Reset to defaults"
        foreground: root.ink; accent: root.accent; bordered: true
        hasCursor: root.cursorRow === 0 && root.cursorCol === 0
        Accessible.role: Accessible.Button
        Accessible.name: "Reset Customize choices to defaults"
        onClicked: root.panel.resetSettings()
      }
      Button {
        text: "Done"
        foreground: root.ink; accent: root.accent; bordered: true
        hasCursor: root.cursorRow === 0 && root.cursorCol === 1
        Accessible.role: Accessible.Button
        Accessible.name: "Done, return to the world view"
        onClicked: root.done()
      }
    }
  }

  Text {
    width: parent.width
    text: root.panel.appearanceNote
    wrapMode: Text.WordWrap
    color: root.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    bottomPadding: Style.space(4)
  }

  Choice {
    id: styleRow
    width: parent.width
    keyboard: root; rowIndex: 1
    label: "Window style"
    ink: root.ink; accent: root.accent
    current: root.panel.styleSetting
    options: [
      { value: "auto", text: "Auto · " + root.panel.autoStyleName },
      { value: "glass", text: "Glass" },
      { value: "woodblock", text: "Woodblock" },
      { value: "ink", text: "Ink" },
      { value: "neon", text: "Neon" }
    ]
    onPicked: function(v) { root.panel.saveSettings({ style: v }) }
  }
  Choice {
    id: motionRow
    width: parent.width
    keyboard: root; rowIndex: 2
    label: "Motion"
    ink: root.ink; accent: root.accent
    current: root.panel.motion ? "animated" : "quiet"
    options: [{ value: "animated", text: "Animated" }, { value: "quiet", text: "Quiet" }]
    onPicked: function(v) { root.panel.saveSettings({ motion: v }) }
  }
  Choice {
    id: clocksRow
    width: parent.width
    keyboard: root; rowIndex: 3
    label: "World clocks"
    ink: root.ink; accent: root.accent
    current: root.panel.compactClocks ? "compact" : "expanded"
    options: [{ value: "compact", text: "Compact" }, { value: "expanded", text: "Expanded" }]
    onPicked: function(v) { root.panel.saveSettings({ clockLayout: v }) }
  }
  Choice {
    id: timeRow
    width: parent.width
    keyboard: root; rowIndex: 4
    label: "Time"
    ink: root.ink; accent: root.accent
    current: root.panel.h24 ? "24" : "12"
    options: [{ value: "12", text: "3:42 PM" }, { value: "24", text: "15:42" }]
    onPicked: function(v) { root.panel.setHourCycle(v === "24") }
  }
  Choice {
    id: unitRow
    width: parent.width
    keyboard: root; rowIndex: 5
    label: "Temperature"
    ink: root.ink; accent: root.accent
    current: root.panel.imperial ? "imperial" : "metric"
    options: [{ value: "metric", text: "°C · km/h" }, { value: "imperial", text: "°F · mph" }]
    onPicked: function(v) { root.panel.saveSettings({ unit: v }) }
  }
  Choice {
    id: calendarRow
    width: parent.width
    keyboard: root; rowIndex: 6
    label: "Calendar"
    ink: root.ink; accent: root.accent
    current: !root.panel.showCalendar ? "hide" : root.panel.compactCalendar ? "compact" : "expanded"
    options: [{ value: "expanded", text: "Expanded" }, { value: "compact", text: "Compact" }, { value: "hide", text: "Hidden" }]
    onPicked: function(v) {
      root.panel.saveSettings(v === "hide" ? { calendar: "hide" } : { calendar: "show", calendarLayout: v })
    }
  }
  Choice {
    id: weekRow
    width: parent.width
    keyboard: root; rowIndex: 7
    label: "Week starts"
    ink: root.ink; accent: root.accent
    current: root.panel.weekStart
    options: [{ value: 0, text: "Sunday" }, { value: 1, text: "Monday" }]
    onPicked: function(v) { root.panel.saveSettings({ weekStartDay: v === 0 ? "sunday" : "monday" }) }
  }
  Choice {
    id: barTimeRow
    width: parent.width
    keyboard: root; rowIndex: 8
    label: "Bar time"
    ink: root.ink; accent: root.accent
    current: root.panel.barPreset
    options: [
      { value: "day", text: Qt.formatDateTime(root.sample, root.panel.barFormat("day")) },
      { value: "date", text: Qt.formatDateTime(root.sample, root.panel.barFormat("date")) },
      { value: "time", text: Qt.formatDateTime(root.sample, root.panel.barFormat("time")) }
    ]
    onPicked: function(v) { root.panel.saveSettings({ format: root.panel.barFormat(v) }) }
  }
  Choice {
    id: barWeatherRow
    width: parent.width
    keyboard: root; rowIndex: 9
    label: "Bar weather"
    ink: root.ink; accent: root.accent
    current: root.panel.barWeather ? "show" : "hide"
    options: [{ value: "show", text: "Show" }, { value: "hide", text: "Hide" }]
    onPicked: function(v) { root.panel.saveSettings({ barWeather: v === "show" }) }
  }

  Text {
    width: parent.width
    topPadding: Style.space(6)
    text: "↑↓ choose a row · ←→ option · Enter apply · Tab next · Esc back. Cities live in locations.json; right-click the bar clock for more formats."
    wrapMode: Text.WordWrap
    color: root.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
