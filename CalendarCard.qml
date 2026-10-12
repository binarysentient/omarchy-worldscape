import QtQuick
import qs.Commons
import qs.Ui

// Left column: today's headline and the home weather card (Expanded), then
// the month. Dates the home forecast covers carry a small glyph; clicking one
// shows that day in the home card.
Column {
  id: root

  property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property var weeks: []
  property var weekdays: []
  property bool expanded: true
  property string moodTitle: ""
  property string moodNext: ""
  property string moodDetail: ""
  property bool moodPicked: false
  property var forecast: ({})      // "YYYY-MM-DD" → { glyph, wet }
  property string selectedKey: ""
  property string sans: "sans-serif"
  readonly property string mono: Style.font.family
  readonly property bool hasForecast: Object.keys(forecast).length > 0
  property color ink: Color.popups.text
  property color dim: ink
  property color surface: "transparent"
  property color accent: Color.accent
  property color todayText: Color.popups.background

  signal previousMonth()
  signal nextMonth()
  signal goToday()
  signal pickDay(string key)

  spacing: Style.space(10)

  Column {
    visible: root.expanded
    width: parent.width
    spacing: Style.space(2)
    Text {
      width: parent.width
      text: Qt.formatDate(root.today, "dddd")
      elide: Text.ElideRight
      color: root.ink
      font.family: root.sans
      font.weight: Font.Light
      font.pixelSize: Style.space(28)
    }
    Text {
      text: Qt.formatDate(root.today, "d MMMM yyyy")
      color: root.dim
      font.family: root.sans
      font.pixelSize: Style.font.subtitle
    }
  }

  Rectangle {
    // Compact hides the card, except to show a picked forecast day.
    visible: (root.expanded || root.moodPicked) && root.moodTitle !== ""
    width: parent.width
    height: mood.implicitHeight + Style.space(18)
    radius: Style.space(10)
    color: root.surface
    border.width: root.moodPicked ? 1 : 0
    border.color: root.accent
    Column {
      id: mood
      x: Style.space(11); y: Style.space(9)
      width: parent.width - Style.space(22)
      spacing: Style.space(2)
      Text {
        width: parent.width
        text: root.moodTitle
        wrapMode: Text.WordWrap
        color: root.ink
        font.family: root.sans
        font.weight: Font.DemiBold
        font.pixelSize: Style.font.heading
      }
      Text {
        visible: text !== ""
        width: parent.width
        text: root.moodNext
        wrapMode: Text.WordWrap
        color: root.accent
        font.family: root.mono
        font.pixelSize: Style.font.bodySmall
      }
      Text {
        width: parent.width
        text: root.moodDetail
        wrapMode: Text.WordWrap
        color: root.dim
        font.family: root.mono
        font.pixelSize: Style.font.bodySmall
      }
    }
  }

  Item {
    width: parent.width
    height: Style.space(28)
    PanelActionButton {
      anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
      iconText: "󰅁"; tooltipText: "Previous month"
      foreground: root.ink; onClicked: root.previousMonth()
    }
    Text {
      anchors.centerIn: parent
      text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
      color: root.ink
      font.family: root.sans
      font.pixelSize: Style.font.subtitle
      font.weight: Font.DemiBold
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.goToday() }
    }
    PanelActionButton {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      iconText: "󰅂"; tooltipText: "Next month"
      foreground: root.ink; onClicked: root.nextMonth()
    }
  }

  Column {
    id: grid
    width: parent.width
    spacing: Style.space(2)
    Row {
      Repeater {
        model: root.weekdays
        Text {
          required property var modelData
          width: grid.width / 7; height: Style.space(20)
          text: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][modelData]
          horizontalAlignment: Text.AlignHCenter
          color: root.dim
          font.family: root.mono
          font.pixelSize: Style.font.caption
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
            id: cell
            required property var modelData
            readonly property var fc: root.forecast[modelData.key] || null
            readonly property bool picked: fc !== null && !modelData.today && modelData.key === root.selectedKey
            width: grid.width / 7; height: Style.space(root.hasForecast ? 36 : 25)
            radius: Style.space(7)
            color: modelData.today ? root.accent : hover.containsMouse && fc ? Util.alpha(root.ink, 0.08) : "transparent"
            border.width: picked ? 1 : 0
            border.color: root.accent
            // Numbers keep one baseline whether or not a glyph sits below.
            Column {
              anchors.horizontalCenter: parent.horizontalCenter
              y: root.hasForecast ? Style.space(4) : (parent.height - height) / 2
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cell.modelData.day
                color: cell.modelData.today ? root.todayText : root.ink
                opacity: cell.modelData.inMonth ? 1 : 0.35
                font.family: root.mono
                font.pixelSize: Style.font.bodySmall
                font.bold: cell.modelData.today
              }
              Text {
                visible: cell.fc !== null
                anchors.horizontalCenter: parent.horizontalCenter
                text: cell.fc ? cell.fc.glyph : ""
                color: cell.modelData.today ? root.todayText : cell.fc && cell.fc.wet ? root.accent : root.dim
                font.family: root.mono
                font.pixelSize: Style.font.caption
              }
            }
            MouseArea {
              id: hover
              anchors.fill: parent
              enabled: cell.fc !== null
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.pickDay(cell.modelData.key)
            }
          }
        }
      }
    }
  }

  Text {
    width: parent.width
    text: "T today · ← → month · W week start" + (root.hasForecast ? " · click a day for its forecast" : "")
    wrapMode: Text.WordWrap
    color: root.dim
    font.family: root.mono
    font.pixelSize: Style.font.caption
  }
}
