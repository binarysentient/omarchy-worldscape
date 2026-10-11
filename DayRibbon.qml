import QtQuick
import qs.Commons
import "Sky.js" as Sky

// Every city on one 0–24 h band, coloured by the home city's sky, so you can
// see at a glance who is asleep and who is at golden hour.
Item {
  id: root

  property var cities: []     // [{ name, hour, local }]
  property var sun: ({ sunrise: 6.5, sunset: 18.5, polar: "" })
  property string style: "glass"
  property var pal: ({ bg: "#000000", fg: "#ffffff", accent: "#7aa2f7", warm: "#e0af68", green: "#9ece6a" })
  property color ink: Color.popups.text
  property color surface: Color.popups.background
  property string fontFamily: Style.font.family

  implicitHeight: Style.space(40)

  readonly property real bandY: Style.space(8)
  readonly property real bandH: Style.space(8)
  readonly property string paintKey: [width, style, JSON.stringify(pal), sun.sunrise.toFixed(2), sun.sunset.toFixed(2), sun.polar].join("|")
  onPaintKeyChanged: band.requestPaint()

  Canvas {
    id: band
    x: 0; y: root.bandY
    width: root.width; height: root.bandH
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      if (width <= 0) return
      var g = ctx.createLinearGradient(0, 0, width, 0)
      for (var k = 0; k <= 48; k++) {
        var s = Sky.skyAt(k / 2, root.sun)
        g.addColorStop(k / 48, Sky.tint(Sky.mix(s[0], s[1], 0.55), root.style, root.pal))
      }
      var r = height / 2
      ctx.fillStyle = g
      ctx.beginPath()
      ctx.moveTo(r, 0); ctx.lineTo(width - r, 0); ctx.arc(width - r, r, r, -Math.PI / 2, Math.PI / 2)
      ctx.lineTo(r, height); ctx.arc(r, r, r, Math.PI / 2, Math.PI * 1.5)
      ctx.closePath(); ctx.fill()
    }
  }

  Repeater {
    model: root.cities
    Rectangle {
      required property var modelData
      readonly property real d: Style.space(18)
      width: d; height: d; radius: d / 2
      x: Math.max(0, Math.min(root.width - d, modelData.hour / 24 * root.width - d / 2))
      y: root.bandY + root.bandH / 2 - d / 2
      color: root.surface
      border.width: Math.max(1, Style.space(2))
      border.color: modelData.local ? Color.accent : Util.alpha(root.ink, 0.6)
      Text {
        anchors.centerIn: parent
        text: String(parent.modelData.name || "?").charAt(0)
        color: root.ink
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }

  Repeater {
    model: ["00", "06", "12", "18", "24"]
    Text {
      required property string modelData
      required property int index
      x: index / 4 * root.width - implicitWidth * index / 4
      y: root.bandY + root.bandH + Style.space(9)
      text: modelData
      color: root.ink
      opacity: 0.55
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
