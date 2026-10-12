import QtQuick
import qs.Commons
import "Sky.js" as Sky

// Every city on one 0–24 h band, coloured by the home city's sky, so you can
// see at a glance who is asleep and who is at golden hour.
Item {
  id: root

  property var cities: []     // [{ name, hour, local, time }]
  property var sun: ({ sunrise: 6.5, sunset: 18.5, polar: "" })
  property string style: "glass"
  property var pal: ({ bg: "#000000", fg: "#ffffff", accent: "#7aa2f7", warm: "#e0af68", green: "#9ece6a" })
  property color ink: Color.popups.text
  property color surface: Color.popups.background
  property color dim: ink
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property var ordered: cities.slice().sort(function(a, b) { return a.hour - b.hour })
  implicitHeight: bandY + bandH + Style.space(7) + Style.font.caption + Style.space(6)

  readonly property real bandY: Style.font.caption + Style.space(10)
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

  // Sunrise and sunset at home, as small ticks through the band.
  Repeater {
    model: root.sun.polar ? [] : [root.sun.sunrise, root.sun.sunset]
    Rectangle {
      required property real modelData
      x: Math.round(modelData / 24 * root.width)
      y: root.bandY - Style.space(4)
      width: 1; height: root.bandH + Style.space(8)
      color: root.dim
    }
  }

  // A dot per city on its local hour; labels alternate above and below the
  // band (in hour order) so neighbours don't collide, and stay inside the
  // ribbon at the ends.
  Repeater {
    model: root.ordered
    Item {
      id: mark
      required property var modelData
      required property int index
      readonly property real cx: modelData.hour / 24 * root.width
      readonly property real d: Style.space(12)
      Rectangle {
        x: Math.max(0, Math.min(root.width - mark.d, mark.cx - mark.d / 2))
        y: root.bandY + root.bandH / 2 - mark.d / 2
        width: mark.d; height: mark.d; radius: mark.d / 2
        color: mark.modelData.local ? root.accent : root.surface
        border.width: Math.max(1, Style.space(2))
        border.color: mark.modelData.local ? root.accent : root.ink
      }
      Row {
        x: Math.max(0, Math.min(root.width - width, mark.cx - width / 2))
        y: mark.index % 2 === 0 ? 0 : root.bandY + root.bandH + Style.space(7)
        spacing: Style.space(5)
        Text {
          text: mark.modelData.name + (mark.modelData.local ? " (you)" : "")
          color: mark.modelData.local ? root.accent : root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          text: mark.modelData.time || ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
