import QtQuick
import qs.Commons
import qs.Ui

// Left column: today's headline and home mood (Expanded), then the month.
Column {
  id: root

  property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property var weeks: []
  property var weekdays: []
  property bool expanded: true
  property string moodTitle: ""
  property string moodDetail: ""
  property var type: ({ family: Style.font.family, weight: Font.Normal, italicMood: false })
  property color ink: Color.popups.text
  property color dim: ink
  property color surface: "transparent"
  property color accent: Color.accent
  property color todayText: Color.popups.background

  signal previousMonth()
  signal nextMonth()
  signal goToday()

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
      font.family: root.type.family
      font.weight: root.type.weight
      font.pixelSize: Style.space(28)
    }
    Text {
      text: Qt.formatDate(root.today, "d MMMM yyyy")
      color: root.dim
      font.family: root.type.family
      font.pixelSize: Style.font.body
    }
  }

  Rectangle {
    visible: root.expanded && root.moodTitle !== ""
    width: parent.width
    height: mood.implicitHeight + Style.space(18)
    radius: Style.space(10)
    color: root.surface
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
        font.family: root.type.family
        font.weight: Font.DemiBold
        font.italic: root.type.italicMood
        font.pixelSize: Style.font.title
      }
      Text {
        width: parent.width
        text: root.moodDetail
        wrapMode: Text.WordWrap
        color: root.dim
        font.family: Style.font.family
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
      font.family: root.type.family
      font.pixelSize: Style.font.body
      font.bold: true
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
          font.family: Style.font.family
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
            required property var modelData
            width: grid.width / 7; height: Style.space(25)
            radius: Style.space(7)
            color: modelData.today ? root.accent : "transparent"
            Text {
              anchors.centerIn: parent
              text: parent.modelData.day
              color: parent.modelData.today ? root.todayText : root.ink
              opacity: parent.modelData.inMonth ? 1 : 0.35
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: parent.modelData.today
            }
          }
        }
      }
    }
  }

  Text {
    width: parent.width
    text: "T today · ← → month · W week start"
    elide: Text.ElideRight
    color: root.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
