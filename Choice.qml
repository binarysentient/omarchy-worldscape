import QtQuick
import qs.Commons

// One Customize row: a label and a few named options. Shows a readable
// preview in each option rather than exposing raw values. Options wrap onto
// further lines when the panel is narrow, so the label is never squeezed out.
//
// Keyboard: the owning view sets `keyboard` (an object with cursorRow and
// cursorCol) and this row's `rowIndex`; the option under the cursor gets a
// focus ring and the whole row a soft highlight.
Item {
  id: root

  property string label: ""
  property var options: []   // [{ value, text }]
  property var current
  property color ink: Color.popups.text
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property var keyboard: null
  property int rowIndex: -1

  readonly property int cursor: keyboard && keyboard.cursorRow === rowIndex ? keyboard.cursorCol : -1
  readonly property bool active: cursor >= 0
  readonly property int chosenIndex: {
    for (var i = 0; i < options.length; i++) if (String(options[i].value) === String(current)) return i
    return -1
  }
  readonly property real labelWidth: Math.min(Style.space(118), width * 0.34)

  signal picked(var value)

  function pickAt(i) {
    if (i >= 0 && i < options.length) picked(options[i].value)
  }

  implicitHeight: Math.max(Style.space(30), caption.implicitHeight, pills.implicitHeight) + Style.space(6)

  Accessible.role: Accessible.Grouping
  Accessible.name: label

  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: -Style.space(6)
    anchors.rightMargin: -Style.space(6)
    radius: Style.space(6)
    color: root.active ? Style.hoverFillFor(root.ink, root.accent) : "transparent"
  }

  Text {
    id: caption
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: root.labelWidth
    text: root.label
    wrapMode: Text.WordWrap
    color: root.ink
    opacity: root.active ? 1 : 0.72
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    font.bold: root.active
  }

  Flow {
    id: pills
    anchors.left: caption.right
    anchors.leftMargin: Style.space(10)
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(3)

    Repeater {
      model: root.options
      Rectangle {
        id: pill
        required property var modelData
        required property int index
        readonly property bool chosen: index === root.chosenIndex
        readonly property bool focused: index === root.cursor
        width: Math.min(pills.width, caption2.implicitWidth + Style.space(16))
        height: Style.space(24)
        radius: Style.space(6)
        color: chosen ? Style.selectedFillFor(root.ink, root.accent)
          : (hover.containsMouse || focused) ? Style.hoverFillFor(root.ink, root.accent) : "transparent"
        border.width: focused ? Math.max(2, Style.space(2)) : chosen ? 1 : 0
        border.color: focused ? root.ink : root.accent

        Accessible.role: Accessible.RadioButton
        Accessible.name: root.label + ": " + modelData.text
        Accessible.checkable: true
        Accessible.checked: chosen
        Accessible.focused: focused
        Accessible.onPressAction: root.pickAt(index)

        Text {
          id: caption2
          anchors.centerIn: parent
          width: Math.min(implicitWidth, pills.width - Style.space(16))
          elide: Text.ElideRight
          text: pill.modelData.text
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: pill.chosen
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.pickAt(pill.index)
        }
      }
    }
  }
}
