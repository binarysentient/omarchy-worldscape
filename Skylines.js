// City silhouettes for the windows. Coordinates live in a 120 × 180 box with
// the street at the bottom (y = 180); the window scales and anchors them to
// its own size. Paths use a small subset of SVG path syntax (M L H V Q T Z,
// absolute or relative) so they are easy to edit by hand.
//
// To add a city: give it an entry below and a matcher in `forCity`. Anything
// unmatched gets the neighbourhood rooftops, which suit most places.

var SKYLINES = {
  // CN Tower among downtown blocks.
  toronto: {
    paths: ["M0 180V146h7v-16h9v-8h8v24h5v-30h10v30h4v-12h8v12h5L58 100h-2.5l1.5-6h2.5L60.2 64h1V40h0.8v24h1L65 94h2.5l1.5 6h-2.5L68 146h4v-22h9v22h5v-14h10v14h4v-8h7v8H120V180Z"],
    lights: [[10, 136], [19, 128], [32, 124], [35, 134], [46, 140], [61.6, 97], [75, 130], [78, 138], [90, 140], [103, 142]]
  },
  // Rolling hills, a low office campus and palms.
  valley: {
    paths: ["M0 180V150Q22 134 46 146T92 140Q108 136 120 142V180Z", "M48 180V141h22v5h9V180Z"],
    palms: [[86, 141], [24, 143]],
    lights: [[40, 152], [53, 146], [61, 146], [66, 153], [104, 152]]
  },
  // Elizabeth Tower, terraces and St Paul's dome.
  london: {
    paths: ["M0 180V154h10v-8h12v8h8v-28h2l4-10 4 10h2v28h8v-12h16v12h8v-6h14v6h4v-10h4v-6q8-16 16 0v6h4v10H120V180Z"],
    clock: [36, 131],
    lights: [[14, 150], [35, 138], [56, 147], [80, 151], [104, 144]]
  },
  // Palace dome and a slender minaret.
  vadodara: {
    paths: ["M0 180V154h16v-12h8q10-18 20 0h8v12h12v-8h4v-10l2-4 2 4v10h4v8h44V180Z"],
    palms: [[100, 154]],
    lights: [[20, 150], [34, 146], [70, 150], [86, 156]]
  },
  // Neighbourhood rooftops and trees: the default for any other city.
  rooftops: {
    paths: ["M0 180V152l10-9 10 9h4v-14h16v14h6l12-11 12 11h8l7-6 7 6h6v-8h12v8h10V180Z"],
    trees: [[44, 152, 6], [104, 148, 5]],
    lights: [[13, 148], [30, 143], [56, 146], [88, 149], [103, 146]]
  }
}

function forCity(city, region) {
  var name = String(city || "").toLowerCase()
  var where = String(region || "").toLowerCase()
  if (name.indexOf("toronto") >= 0) return SKYLINES.toronto
  if (name.indexOf("silicon valley") >= 0 || name === "san jose" || name === "palo alto" || name === "mountain view") return SKYLINES.valley
  if (name.indexOf("london") >= 0 && where.indexOf("ontario") < 0) return SKYLINES.london
  if (name.indexOf("vadodara") >= 0 || name.indexOf("baroda") >= 0) return SKYLINES.vadodara
  return SKYLINES.rooftops
}

// Trace a path onto a Canvas 2D context through a point transform.
function trace(ctx, d, map) {
  var tokens = String(d).match(/[MLHVQTZmlhvqtz]|-?\d*\.?\d+(?:e-?\d+)?/g) || []
  var i = 0, cmd = "", x = 0, y = 0, sx = 0, sy = 0, qx = 0, qy = 0, lastQ = false
  function num() { return parseFloat(tokens[i++]) }
  function to(px, py) { var p = map(px, py); ctx.lineTo(p[0], p[1]) }
  ctx.beginPath()
  while (i < tokens.length) {
    if (/[A-Za-z]/.test(tokens[i])) cmd = tokens[i++]
    var rel = cmd === cmd.toLowerCase() && cmd !== "z" ? true : false
    var C = cmd.toUpperCase()
    var ox = rel ? x : 0, oy = rel ? y : 0
    if (C === "M") {
      x = ox + num(); y = oy + num(); sx = x; sy = y
      var m = map(x, y); ctx.moveTo(m[0], m[1])
      cmd = rel ? "l" : "L"; lastQ = false
    } else if (C === "L") { x = ox + num(); y = oy + num(); to(x, y); lastQ = false }
    else if (C === "H") { x = ox + num(); to(x, y); lastQ = false }
    else if (C === "V") { y = oy + num(); to(x, y); lastQ = false }
    else if (C === "Q" || C === "T") {
      var cx, cy
      if (C === "Q") { cx = ox + num(); cy = oy + num() }
      else { cx = lastQ ? 2 * x - qx : x; cy = lastQ ? 2 * y - qy : y }
      var ex = ox + num(), ey = oy + num()
      var c = map(cx, cy), e = map(ex, ey)
      ctx.quadraticCurveTo(c[0], c[1], e[0], e[1])
      qx = cx; qy = cy; x = ex; y = ey; lastQ = true
    } else if (C === "Z") { ctx.closePath(); x = sx; y = sy; lastQ = false; cmd = "" }
    else i++
  }
}

if (typeof module !== "undefined") module.exports = { SKYLINES: SKYLINES, forCity: forCity, trace: trace }
