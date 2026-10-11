import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "Sky.js" as Sky
import "Skylines.js" as Skylines

// One city seen through a window. The still picture (sky, sun or moon,
// skyline, lamps) is a Canvas repainted only when its inputs change, about
// once a minute. Motion lives in a few light items on top — drifting clouds,
// a scrolling rain/snow sheet, twinkling stars, a lightning flash — and only
// runs while `animate` is true. Text never sits on the artwork.
Item {
  id: root

  property string city: ""
  property string region: ""
  property var latitude: null
  property var longitude: null
  property real utcMs: Date.now()
  property int offsetMinutes: 0
  property var weatherCode: null
  property string style: "glass"
  property bool compact: false
  property bool animate: false
  // {bg, fg, accent, warm, green} as "#rrggbb"
  property var pal: ({ bg: "#1a1b26", fg: "#a9b1d6", accent: "#7aa2f7", warm: "#e0af68", green: "#9ece6a" })

  // ---- What the scene shows
  readonly property real hour: {
    var d = new Date(utcMs + offsetMinutes * 60000)
    return d.getUTCHours() + d.getUTCMinutes() / 60
  }
  readonly property var sun: Sky.solarDay(latitude, longitude, utcMs, offsetMinutes)
  readonly property bool night: Sky.isNight(hour, sun)
  readonly property string kind: Sky.weatherKind(weatherCode)
  readonly property var skyline: Skylines.forCity(city, region)
  readonly property bool heavy: kind === "rain" || kind === "storm" || kind === "snow"
  readonly property bool veiled: heavy || kind === "fog" || kind === "cloud"
  readonly property bool ink: style === "ink"
  readonly property bool neon: style === "neon"

  // ---- Geometry: a 120-wide virtual box, as tall as the window's aspect.
  readonly property real unit: width / 120
  readonly property real virtualHeight: unit > 0 ? height / unit : 180
  readonly property real landScale: Math.max(0.62, Math.min(1, virtualHeight / 180))
  readonly property real horizon: virtualHeight - 36 * landScale
  readonly property real arc: Sky.arcProgress(hour, sun)
  readonly property real bodyX: (10 + arc * 100) * unit
  readonly property real bodyY: (horizon - Math.sin(Math.PI * arc) * (horizon - 16)) * unit
  readonly property bool showBody: kind === "clear" || kind === "partly" || kind === "unknown"

  // ---- Colours, derived once per change rather than per paint call.
  readonly property var colors: {
    var s = Sky.skyAt(hour, sun)
    var top = Sky.tint(s[0], style, pal), bottom = Sky.tint(s[1], style, pal)
    if (kind === "unknown") {
      top = Sky.mix(top, night ? "#2a2e36" : "#80868f", 0.45)
      bottom = Sky.mix(bottom, night ? "#33373f" : "#a3a8af", 0.45)
    } else if (veiled || kind === "partly") {
      var w = kind === "partly" ? 0.18 : 0.5
      top = Sky.mix(top, night ? "#1d212b" : "#7f8998", w)
      bottom = Sky.mix(bottom, night ? "#2b303c" : "#b8bfc8", w)
    }
    var low = !night && bodyY > (horizon - 30) * unit
    var groundFar = ink ? pal.bg
      : style === "woodblock" ? Sky.mix(Sky.mix(pal.green, "#120f0b", 0.55), bottom, 0.5)
      : null
    var groundNear = ink ? pal.bg
      : neon ? Sky.mix(pal.bg, "#000000", 0.3)
      : style === "woodblock" ? Sky.mix(pal.green, "#120f0b", 0.55)
      : Sky.mix(Sky.mix(bottom, "#0a0f1c", 0.62), pal.bg, 0.25)
    return {
      top: top, bottom: bottom, middle: Sky.mix(top, bottom, 0.5),
      line: pal.fg,
      sun: neon ? pal.accent : low ? "#ffb067" : "#fff0b0",
      moon: "#eef0ff",
      far: groundFar || Sky.mix(groundNear, bottom, 0.45),
      near: groundNear,
      lamp: ink ? pal.fg : pal.warm,
      cloud: ink ? pal.bg : heavy ? (night ? "#2a303b" : "#6d7685") : night ? "#59627a" : "#f3f5f7",
      rain: ink ? pal.fg : night ? "#a9c4dd" : "#e4edf5",
      fog: ink ? pal.fg : night ? "#9aa3b3" : "#eef0f2"
    }
  }
  readonly property bool lampsOn: night || (veiled && hour > sun.sunset - 2) || hour < sun.sunrise + 0.5

  // Anything the still picture depends on; a change asks for one repaint.
  readonly property string paintKey: [city, region, width, height, Math.round(hour * 60), kind, style, compact,
    JSON.stringify(pal), sun.sunrise.toFixed(2), sun.sunset.toFixed(2)].join("|")
  onPaintKeyChanged: { scene.requestPaint(); stars.requestPaint(); sheet.requestPaint(); bolt.requestPaint() }

  function skyY(y) { return y * (horizon / 142) * unit }

  // ---- Frame outline shared by the mask and the drawn edge.
  readonly property real topRadius: style === "glass"
    ? (compact ? Math.min(width / 2, height * 0.55) : width / 2)
    : style === "ink" ? 2 : style === "woodblock" ? 5 : 4
  readonly property real bottomRadius: style === "glass" ? Math.min(14, height / 4) : topRadius
  readonly property string outline: {
    var w = width, h = height, t = Math.min(topRadius, w / 2, h / 2), b = Math.min(bottomRadius, w / 2, h / 2)
    return "M 0 " + t + " A " + t + " " + t + " 0 0 1 " + t + " 0 L " + (w - t) + " 0 A " + t + " " + t + " 0 0 1 " + w + " " + t
      + " L " + w + " " + (h - b) + " A " + b + " " + b + " 0 0 1 " + (w - b) + " " + h + " L " + b + " " + h
      + " A " + b + " " + b + " 0 0 1 0 " + (h - b) + " Z"
  }

  Item {
    id: mask
    anchors.fill: parent
    visible: false
    layer.enabled: true
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath { fillColor: "white"; strokeColor: "transparent"; PathSvg { path: root.outline } }
    }
  }

  Item {
    id: art
    anchors.fill: parent
    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: mask
      maskThresholdMin: 0.3
      maskSpreadAtMin: 0.3
    }

    Canvas {
      id: scene
      anchors.fill: parent
      onPaint: root.paintScene(getContext("2d"))
    }

    // Stars on their own sheet so they can breathe without a repaint.
    Canvas {
      id: stars
      anchors.fill: parent
      visible: root.night && !root.heavy
      opacity: 1
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        if (!root.night) return
        ctx.fillStyle = root.ink ? root.colors.line : "#ffffff"
        ctx.globalAlpha = root.veiled || root.kind === "unknown" ? 0.25 : 0.85
        for (var k = 0; k < 16; k++) {
          var x = ((k * 37 + root.city.length * 11) % 116 + 2) * root.unit
          var y = root.skyY((k * 23) % 96 + 6)
          var r = (k % 4 ? 0.5 : 0.9) * root.unit
          ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill()
        }
      }
      SequentialAnimation on opacity {
        running: root.animate && stars.visible
        loops: Animation.Infinite
        NumberAnimation { to: 0.55; duration: 1700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 1700; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) stars.opacity = 1
      }
    }

    // Soft breathing glow behind the sun or moon.
    Rectangle {
      id: glow
      visible: root.showBody && !root.ink && root.kind !== "unknown"
      readonly property real size: (root.night ? 32 : root.bodyY > (root.horizon - 30) * root.unit ? 52 : 40) * root.unit
      width: size; height: size; radius: size / 2
      x: root.bodyX - size / 2; y: root.bodyY - size / 2
      color: root.night ? "#dfe6ff" : root.colors.sun
      opacity: root.night ? 0.12 : 0.3
      SequentialAnimation on scale {
        running: root.animate && glow.visible
        loops: Animation.Infinite
        NumberAnimation { to: 1.15; duration: 3000; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 3000; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) glow.scale = 1
      }
    }

    Repeater {
      model: root.cloudSpecs
      Cloud {
        required property var modelData
        unit: root.unit
        cx: modelData.x * root.unit
        cy: root.skyY(modelData.y)
        size: modelData.s
        drift: modelData.d
        fill: root.colors.cloud
        stroke: root.ink ? root.colors.line : ""
        opacity: modelData.o
        animate: root.animate
      }
    }

    // Rain or snow: one pre-drawn sheet, twice the window height, slid down.
    Item {
      anchors.fill: parent
      clip: true
      visible: root.kind === "rain" || root.kind === "storm" || root.kind === "snow"
      Canvas {
        id: sheet
        width: parent.width
        height: parent.height * 2
        y: -parent.height
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var snow = root.kind === "snow", h = parent ? parent.height : root.height
          if (!(root.kind === "rain" || root.kind === "storm" || snow)) return
          var count = Math.round((snow ? 18 : 24) * Math.max(0.6, root.virtualHeight / 180))
          ctx.globalAlpha = snow ? 0.9 : 0.7
          ctx.strokeStyle = root.colors.rain
          ctx.fillStyle = root.ink ? root.colors.line : "#ffffff"
          ctx.lineWidth = Math.max(1, root.unit * 0.8)
          for (var copy = 0; copy < 2; copy++) {
            for (var k = 0; k < count; k++) {
              var x = ((k * 29 + root.city.length * 7) % 124) * root.unit
              var y = ((k * 41) % 97) / 97 * h + copy * h
              if (snow) {
                ctx.beginPath(); ctx.arc(x, y, (k % 3 ? 1 : 1.6) * root.unit, 0, Math.PI * 2); ctx.fill()
              } else {
                ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x - 3 * root.unit, y + 9 * root.unit); ctx.stroke()
              }
            }
          }
        }
        NumberAnimation on y {
          running: root.animate && sheet.parent.visible
          loops: Animation.Infinite
          from: -sheet.parent.height; to: 0
          duration: root.kind === "snow" ? 9000 : 900
          onRunningChanged: if (!running) sheet.y = -sheet.parent.height
        }
      }
    }

    Repeater {
      model: root.kind === "fog" ? 4 : 0
      Rectangle {
        id: band
        required property int index
        property real shift: 0
        x: (-20 + shift) * root.unit
        y: root.skyY(96 + index * 13)
        width: 160 * root.unit; height: 9 * root.unit; radius: height / 2
        color: root.colors.fog
        opacity: root.ink ? 0.12 : 0.38
        SequentialAnimation on shift {
          running: root.animate
          loops: Animation.Infinite
          NumberAnimation { from: -8; to: 8; duration: 10000 + band.index * 3000; easing.type: Easing.InOutSine }
          NumberAnimation { from: 8; to: -8; duration: 10000 + band.index * 3000; easing.type: Easing.InOutSine }
        }
      }
    }

    // Storms: a bolt and a brief brightening. Quiet keeps the bolt as a still.
    Rectangle {
      id: flash
      anchors.fill: parent
      visible: root.kind === "storm"
      color: "#ffffff"
      opacity: 0
      SequentialAnimation on opacity {
        running: root.animate && flash.visible
        loops: Animation.Infinite
        PauseAnimation { duration: 5200 }
        NumberAnimation { to: 0.35; duration: 70 }
        NumberAnimation { to: 0; duration: 140 }
        NumberAnimation { to: 0.25; duration: 60 }
        NumberAnimation { to: 0; duration: 300 }
        onRunningChanged: if (!running) flash.opacity = 0
      }
    }
    Canvas {
      id: bolt
      anchors.fill: parent
      visible: root.kind === "storm"
      opacity: root.animate ? flash.opacity * 2.6 : 0.85
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        if (root.kind !== "storm") return
        ctx.fillStyle = root.ink ? root.colors.line : "#fff3b8"
        var u = root.unit, oy = root.skyY(52) - 52 * u
        ctx.beginPath()
        var pts = [[70, 52], [61, 74], [68, 74], [63, 92], [77, 67], [69, 67], [75, 52]]
        for (var i = 0; i < pts.length; i++) {
          var px = pts[i][0] * u, py = oy + pts[i][1] * u
          if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
        }
        ctx.closePath(); ctx.fill()
      }
    }
  }

  // ---- Frame edge, drawn over the artwork.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    visible: root.neon
    opacity: 0.28
    ShapePath { fillColor: "transparent"; strokeColor: root.pal.accent; strokeWidth: 5; PathSvg { path: root.outline } }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.style === "woodblock" ? Sky.mix(root.pal.bg, root.pal.fg, 0.1)
        : root.ink ? root.pal.fg
        : root.neon ? root.pal.accent
        : Sky.mix(root.pal.fg, root.pal.bg, 0.8)
      strokeWidth: root.style === "woodblock" ? 5 : root.ink ? 1.5 : 1
      PathSvg { path: root.outline }
    }
  }

  // Cloud placements per weather, in the virtual box (y measured on a 142
  // sky). x, y, scale, drift seconds, opacity.
  readonly property var cloudSpecs: {
    var c = city.length
    if (kind === "clear") return night ? [] : [{ x: 28 + (c % 4) * 17, y: 42 + (c % 3) * 6, s: 0.7, d: 9 + c % 3, o: 0.55 }]
    if (kind === "partly") return [{ x: 30, y: 46, s: 1.0, d: 11, o: 0.85 }, { x: 86, y: 74, s: 0.75, d: 9, o: 0.75 }]
    if (kind === "cloud") return [{ x: 28, y: 44, s: 1.3, d: 11, o: 0.9 }, { x: 88, y: 70, s: 1.0, d: 8, o: 0.85 }, { x: 50, y: 98, s: 0.8, d: 13, o: 0.7 }]
    if (kind === "fog") return [{ x: 60, y: 40, s: 1.4, d: 14, o: 0.6 }]
    if (heavy) return [{ x: 20, y: 26, s: 1.6, d: 10, o: 0.95 }, { x: 82, y: 30, s: 1.8, d: 12, o: 0.95 }, { x: 54, y: 48, s: 1.4, d: 9, o: 0.9 }]
    return []
  }

  function paintScene(ctx) {
    var c = colors, u = unit, w = width, h = height, ls = landScale
    var map = function(x, y) { return [x * u, h - (180 - y) * ls * u] }
    ctx.reset()
    if (w <= 0 || h <= 0) return

    // Sky
    var g = ctx.createLinearGradient(0, 0, 0, h)
    if (style === "woodblock") {
      ctx.fillStyle = c.top; ctx.fillRect(0, 0, w, h * 0.4)
      ctx.fillStyle = c.middle; ctx.fillRect(0, h * 0.4, w, h * 0.28)
      ctx.fillStyle = c.bottom; ctx.fillRect(0, h * 0.68, w, h * 0.32 + 1)
    } else {
      if (ink) { g.addColorStop(0, Sky.mix(c.top, c.bottom, 0.35)); g.addColorStop(1, Sky.mix(c.top, c.bottom, 0.6)) }
      else { g.addColorStop(0, c.top); g.addColorStop(1, c.bottom) }
      ctx.fillStyle = g; ctx.fillRect(0, 0, w, h)
    }
    if (ink) {
      ctx.strokeStyle = c.line; ctx.globalAlpha = 0.08; ctx.lineWidth = 1
      for (var hy = 10 * u; hy < horizon * u; hy += 8 * u) { ctx.beginPath(); ctx.moveTo(0, hy); ctx.lineTo(w, hy); ctx.stroke() }
      ctx.globalAlpha = 1
    }

    // Sun or moon. With no forecast the body is shown faintly: time is
    // known, the sky's condition is not.
    if (showBody) {
      ctx.globalAlpha = kind === "unknown" ? 0.4 : 1
      var bx = bodyX, by = bodyY
      if (night) {
        ctx.fillStyle = ink ? pal.bg : c.moon
        ctx.beginPath(); ctx.arc(bx, by, 7 * u, 0, Math.PI * 2); ctx.fill()
        if (ink) { ctx.strokeStyle = c.line; ctx.lineWidth = 1.2; ctx.stroke() }
        ctx.fillStyle = ink ? Sky.mix(c.top, c.bottom, 0.35) : c.top
        ctx.beginPath(); ctx.arc(bx + 3.5 * u, by - 2.5 * u, 6 * u, 0, Math.PI * 2); ctx.fill()
      } else if (ink) {
        ctx.strokeStyle = c.line; ctx.lineWidth = 1.2
        ctx.beginPath(); ctx.arc(bx, by, 9 * u, 0, Math.PI * 2); ctx.stroke()
        for (var r = 0; r < 8; r++) {
          var a = r * Math.PI / 4
          ctx.beginPath(); ctx.moveTo(bx + Math.cos(a) * 12 * u, by + Math.sin(a) * 12 * u)
          ctx.lineTo(bx + Math.cos(a) * 17 * u, by + Math.sin(a) * 17 * u); ctx.stroke()
        }
      } else {
        ctx.fillStyle = c.sun
        ctx.beginPath(); ctx.arc(bx, by, (neon ? 13 : 9) * u, 0, Math.PI * 2); ctx.fill()
        if (neon) {
          ctx.fillStyle = c.middle
          for (var s = 0; s < 4; s++) ctx.fillRect(bx - 14 * u, by + (2 + s * 3) * u, 28 * u, (0.8 + s * 0.4) * u)
        }
      }
      ctx.globalAlpha = 1
    }

    // Ground: a far hill, then the city.
    ctx.fillStyle = c.far
    Skylines.trace(ctx, "M0 180V150Q30 136 60 146T120 142V180Z", map)
    ctx.fill()
    if (ink) { ctx.strokeStyle = c.line; ctx.globalAlpha = 0.35; ctx.lineWidth = 1; ctx.stroke(); ctx.globalAlpha = 1 }

    var edge = ink || neon
    ctx.strokeStyle = neon ? pal.accent : c.line
    ctx.lineWidth = 1
    ctx.fillStyle = c.near
    var trees = skyline.trees || []
    for (var t = 0; t < trees.length; t++) {
      var tp = map(trees[t][0], trees[t][1] - trees[t][2])
      ctx.beginPath(); ctx.arc(tp[0], tp[1], trees[t][2] * u * landScale, 0, Math.PI * 2); ctx.fill()
      if (edge) ctx.stroke()
    }
    for (var p = 0; p < skyline.paths.length; p++) {
      Skylines.trace(ctx, skyline.paths[p], map)
      ctx.fill()
      if (edge) ctx.stroke()
    }
    var palms = skyline.palms || []
    ctx.strokeStyle = ink ? c.line : neon ? pal.accent : c.near
    ctx.lineWidth = 1.6 * u * Math.max(0.8, landScale)
    ctx.lineCap = "round"
    for (var q = 0; q < palms.length; q++) {
      var px = palms[q][0], py = palms[q][1]
      var fronds = ["M" + px + " " + py + "q2-14-1-24", "M" + (px - 1) + " " + (py - 24) + "q-8-2-12 4",
                    "M" + (px - 1) + " " + (py - 24) + "q8-3 12 3", "M" + (px - 1) + " " + (py - 24) + "q-4-6-10-6",
                    "M" + (px - 1) + " " + (py - 24) + "q5-6 10-5"]
      for (var f = 0; f < fronds.length; f++) { Skylines.trace(ctx, fronds[f], map); ctx.stroke() }
    }
    if (neon) {
      ctx.strokeStyle = pal.accent; ctx.globalAlpha = 0.35; ctx.lineWidth = 1
      var rows = [158, 164, 173]
      for (var n = 0; n < rows.length; n++) {
        var gy = map(0, rows[n])[1]
        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke()
      }
      ctx.globalAlpha = 1
    }

    // Lamps and, in London, a lit clock face.
    if (lampsOn) {
      ctx.fillStyle = c.lamp
      var size = Math.max(1.5, 2.4 * u * landScale)
      for (var l = 0; l < skyline.lights.length; l++) {
        var lp = map(skyline.lights[l][0], skyline.lights[l][1])
        ctx.fillRect(lp[0], lp[1], size, size)
      }
      if (skyline.clock) {
        var cp = map(skyline.clock[0], skyline.clock[1])
        ctx.beginPath(); ctx.arc(cp[0], cp[1], 2 * u * landScale, 0, Math.PI * 2); ctx.fill()
      }
    }
  }

  onWidthChanged: { scene.requestPaint(); stars.requestPaint(); sheet.requestPaint(); bolt.requestPaint() }
  onHeightChanged: { scene.requestPaint(); stars.requestPaint(); sheet.requestPaint(); bolt.requestPaint() }
}
