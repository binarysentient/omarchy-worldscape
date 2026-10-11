import QtQuick

// A three-puff cloud drawn once and slid gently from side to side.
Canvas {
  id: root

  property real unit: 1
  property real cx: 0
  property real cy: 0
  property real size: 1
  property real drift: 10
  property color fill: "#ffffff"
  property string stroke: ""
  property bool animate: false
  property real shift: 0

  width: 40 * size * unit
  height: 26 * size * unit
  x: cx - width / 2 + shift * unit
  y: cy - height * 0.7

  onFillChanged: requestPaint()
  onStrokeChanged: requestPaint()
  onWidthChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var k = size * unit, ox = width / 2, oy = height * 0.7
    ctx.fillStyle = fill
    ctx.beginPath()
    ctx.ellipse(ox - 18 * k, oy - 7 * k, 36 * k, 14 * k)
    ctx.moveTo(ox - 6 * k + 8 * k, oy - 5 * k)
    ctx.arc(ox - 6 * k, oy - 5 * k, 8 * k, 0, Math.PI * 2)
    ctx.moveTo(ox + 6 * k + 10 * k, oy - 7 * k)
    ctx.arc(ox + 6 * k, oy - 7 * k, 10 * k, 0, Math.PI * 2)
    ctx.fill()
    if (stroke !== "") {
      ctx.strokeStyle = stroke
      ctx.lineWidth = 1
      ctx.stroke()
    }
  }

  SequentialAnimation on shift {
    running: root.animate
    loops: Animation.Infinite
    NumberAnimation { from: -9; to: 9; duration: root.drift * 1000; easing.type: Easing.InOutSine }
    NumberAnimation { from: 9; to: -9; duration: root.drift * 1000; easing.type: Easing.InOutSine }
    onRunningChanged: if (!running) root.shift = 0
  }
}
