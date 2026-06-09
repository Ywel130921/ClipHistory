import AppKit

// ════════════════════════════════════════════
//  ClipHistory App Icon Generator
//  Style: Tool-like, warm industrial precision
//  Output: icon-1024.png (2048×2048 @2x retina)
// ════════════════════════════════════════════

let s: CGFloat = 2048                // output resolution (retina 2x)
let margin: CGFloat = 120
let r2: CGFloat = s / 2               // center
let br: CGFloat = 200                 // board corner radius

let board = CGRect(
    x: margin, y: margin,
    width: s - margin * 2, height: s - margin * 2
)

let paperInset: CGFloat = 80
let paper = CGRect(
    x: board.minX + paperInset,
    y: board.minY + paperInset + 60,   // shift down to leave clip space
    width: board.width - paperInset * 2,
    height: board.height - paperInset * 2 - 60
)
let pr: CGFloat = 140                  // paper corner radius

// ─── Colors ─────────────────────────────────────────
// Board — warm metallic
let boardTop   = NSColor(deviceRed: 0.58, green: 0.60, blue: 0.64, alpha: 1)
let boardBot   = NSColor(deviceRed: 0.32, green: 0.34, blue: 0.38, alpha: 1)
let boardEdge  = NSColor(deviceRed: 0.22, green: 0.23, blue: 0.26, alpha: 1)
let boardShad  = NSColor(deviceRed: 0.08, green: 0.08, blue: 0.10, alpha: 0.50)

// Paper — warm cream
let paperFill  = NSColor(deviceRed: 0.96, green: 0.95, blue: 0.91, alpha: 1)
let paperShad  = NSColor(deviceRed: 0.10, green: 0.10, blue: 0.12, alpha: 0.35)

// Text lines — soft charcoal
let textColor  = NSColor(deviceRed: 0.25, green: 0.25, blue: 0.28, alpha: 0.55)
let textHi     = NSColor(deviceRed: 0.20, green: 0.20, blue: 0.22, alpha: 0.70)

// Accent — warm copper
let copper     = NSColor(deviceRed: 0.80, green: 0.50, blue: 0.25, alpha: 1)
let copperHi   = NSColor(deviceRed: 0.92, green: 0.62, blue: 0.35, alpha: 1)
let copperShad = NSColor(deviceRed: 0.50, green: 0.28, blue: 0.10, alpha: 0.6)

// Clip — polished steel
let clipTop    = NSColor(deviceRed: 0.75, green: 0.77, blue: 0.80, alpha: 1)
let clipBot    = NSColor(deviceRed: 0.55, green: 0.57, blue: 0.60, alpha: 1)
let clipHi     = NSColor(deviceRed: 0.90, green: 0.92, blue: 0.95, alpha: 0.7)

// ─── Helpers ────────────────────────────────────────
func rounded(_ r: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
}

func drawGradient(_ from: NSColor, _ to: NSColor, in path: NSBezierPath, angle: CGFloat = -90) {
    guard let g = NSGradient(starting: from, ending: to) else { return }
    g.draw(in: path, angle: angle)
}

// ─── Render ─────────────────────────────────────────
let image = NSImage(size: NSSize(width: s, height: s))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else {
    print("ERROR: no graphics context")
    exit(1)
}

// ── 1. Background (transparent — let macOS round it) ──
// (intentionally left transparent)

// ── 2. Clipboard board ──
let boardPath = rounded(board, radius: br)

// Board shadow
ctx.saveGState()
let boardShadow = NSShadow()
boardShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
boardShadow.shadowBlurRadius = 40
boardShadow.shadowOffset = NSSize(width: 0, height: -12)
boardShadow.set()
boardPath.fill()
ctx.restoreGState()

// Board gradient fill
drawGradient(boardTop, boardBot, in: boardPath, angle: -90)

// Board edge highlight (top edge)
ctx.saveGState()
boardPath.addClip()
let edgeHiPath = NSBezierPath()
edgeHiPath.move(to: NSPoint(x: board.minX + br * 0.6, y: board.maxY - 4))
edgeHiPath.line(to: NSPoint(x: board.maxX - br * 0.6, y: board.maxY - 4))
NSColor.white.withAlphaComponent(0.15).setStroke()
edgeHiPath.lineWidth = 6
edgeHiPath.stroke()
ctx.restoreGState()

// Board border
boardEdge.setStroke()
boardPath.lineWidth = 6
boardPath.stroke()

// ── 3. Paper ──
let paperPath = rounded(paper, radius: pr)

// Paper drop shadow
ctx.saveGState()
let paperShadow = NSShadow()
paperShadow.shadowColor = paperShad
paperShadow.shadowBlurRadius = 30
paperShadow.shadowOffset = NSSize(width: 0, height: -6)
paperShadow.set()
paperFill.setFill()
paperPath.fill()
ctx.restoreGState()

// Paper actual fill
paperFill.setFill()
paperPath.fill()

// Paper border (very subtle)
NSColor.black.withAlphaComponent(0.06).setStroke()
paperPath.lineWidth = 2
paperPath.stroke()

// ── 4. Paper texture (subtle grain) ──
ctx.saveGState()
paperPath.addClip()
for _ in 0..<1200 {
    let x = CGFloat.random(in: paper.minX...paper.maxX)
    let y = CGFloat.random(in: paper.minY...paper.maxY)
    let alpha = CGFloat.random(in: 0.0...0.06)
    NSColor(deviceWhite: 0.5, alpha: alpha).setFill()
    ctx.fill(CGRect(x: x, y: y, width: 2, height: 2))
}
ctx.restoreGState()

// ── 5. Text lines on paper ──
let lx = paper.minX + 100           // left margin
let rMargin: CGFloat = 100
let ly0: CGFloat = paper.maxY - 200  // bottom of first line (we go upward)
let lineSpacing: CGFloat = 96

let lineLengths: [CGFloat] = [
    0.72, 0.88, 0.42, 0.95, 0.60,
    0.80, 0.50, 0.92,
]

ctx.saveGState()
for (i, ratio) in lineLengths.enumerated() {
    let y = ly0 - CGFloat(i) * lineSpacing
    let w = (paper.width - lx + paper.minX - rMargin) * ratio
    let lw: CGFloat = i == 0 ? 12 : 7   // first line thicker (title)

    if i == 0 {
        // First line — "title" line with accent indicator
        let dotR: CGFloat = 14
        let dotX = lx - 40
        let dotY = y - dotR / 2 + 2
        let dot = NSBezierPath(ovalIn: CGRect(x: dotX, y: dotY, width: dotR, height: dotR))
        copper.setFill()
        dot.fill()
        copperShad.setStroke()
        dot.lineWidth = 1.5
        dot.stroke()

        // Title line
        textHi.setStroke()
    } else {
        textColor.setStroke()
    }

    let line = NSBezierPath()
    line.move(to: NSPoint(x: lx, y: y))
    line.line(to: NSPoint(x: lx + w, y: y))
    line.lineWidth = lw
    line.lineCapStyle = .round
    line.stroke()
}
ctx.restoreGState()

// ── 6. Copper paper clip accent (top-right of paper) ──
let clipX = paper.maxX - 100
let clipY = paper.maxY - 100
let clipR: CGFloat = 50

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 2, height: -2), blur: 8, color: NSColor.black.withAlphaComponent(0.3).cgColor)

let paperclip = NSBezierPath()
paperclip.move(to: NSPoint(x: clipX - clipR, y: clipY + clipR * 1.8))
paperclip.line(to: NSPoint(x: clipX - clipR, y: clipY - clipR * 0.6))
paperclip.curve(
    to: NSPoint(x: clipX + clipR, y: clipY - clipR * 0.6),
    controlPoint1: NSPoint(x: clipX - clipR, y: clipY - clipR * 1.8),
    controlPoint2: NSPoint(x: clipX + clipR, y: clipY - clipR * 1.8)
)
paperclip.line(to: NSPoint(x: clipX + clipR, y: clipY + clipR * 0.6))

copper.setStroke()
paperclip.lineWidth = 10
paperclip.lineCapStyle = .round
paperclip.lineJoinStyle = .round
paperclip.stroke()

// Highlight on paperclip
let hlClip = NSBezierPath()
hlClip.move(to: NSPoint(x: clipX - clipR + 4, y: clipY + clipR * 0.4))
hlClip.line(to: NSPoint(x: clipX - clipR + 4, y: clipY - clipR * 0.3))
copperHi.withAlphaComponent(0.4).setStroke()
hlClip.lineWidth = 3
hlClip.lineCapStyle = .round
hlClip.stroke()

ctx.restoreGState()

// ── 7. Top clip mechanism ──
let topClipW: CGFloat = 300
let topClipH: CGFloat = 150
let tcx = r2 - topClipW / 2
let tcy = board.maxY - 10

let topClip = NSBezierPath()
topClip.move(to: NSPoint(x: tcx, y: tcy))
topClip.line(to: NSPoint(x: tcx, y: tcy + topClipH))
topClip.curve(
    to: NSPoint(x: tcx + topClipW, y: tcy + topClipH),
    controlPoint1: NSPoint(x: tcx + 30, y: tcy + topClipH + 50),
    controlPoint2: NSPoint(x: tcx + topClipW - 30, y: tcy + topClipH + 50)
)
topClip.line(to: NSPoint(x: tcx + topClipW, y: tcy))
topClip.line(to: NSPoint(x: tcx + topClipW - 30, y: tcy - 20))
topClip.line(to: NSPoint(x: tcx + 30, y: tcy - 20))
topClip.close()

// Clip drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 25, color: NSColor.black.withAlphaComponent(0.35).cgColor)
clipTop.setFill()
topClip.fill()
ctx.restoreGState()

// Clip gradient
drawGradient(clipTop, clipBot, in: topClip, angle: -90)

// Clip border
boardEdge.withAlphaComponent(0.4).setStroke()
topClip.lineWidth = 4
topClip.stroke()

// Clip highlight (top edge)
let clipHiPath = NSBezierPath()
clipHiPath.move(to: NSPoint(x: tcx + 50, y: tcy + topClipH + 10))
clipHiPath.curve(
    to: NSPoint(x: tcx + topClipW - 50, y: tcy + topClipH + 10),
    controlPoint1: NSPoint(x: tcx + 70, y: tcy + topClipH + 55),
    controlPoint2: NSPoint(x: tcx + topClipW - 70, y: tcy + topClipH + 55)
)
clipHi.setStroke()
clipHiPath.lineWidth = 8
clipHiPath.lineCapStyle = .round
clipHiPath.stroke()

// ── 8. Overall gloss overlay ──
ctx.saveGState()
boardPath.addClip()
let gloss = NSBezierPath(roundedRect: board, xRadius: br, yRadius: br)
guard let glossGrad = NSGradient(
    starting: NSColor.white.withAlphaComponent(0.06),
    ending: NSColor.white.withAlphaComponent(0.0)
) else { exit(1) }
glossGrad.draw(in: gloss, angle: 90)
ctx.restoreGState()

// ── 9. Very subtle inner shadow on board (bottom edge) ──
ctx.saveGState()
boardPath.addClip()
let innerShad = NSBezierPath()
innerShad.move(to: NSPoint(x: board.minX + 20, y: board.minY + 10))
innerShad.line(to: NSPoint(x: board.maxX - 20, y: board.minY + 10))
NSColor.black.withAlphaComponent(0.15).setStroke()
innerShad.lineWidth = 15
innerShad.stroke()
ctx.restoreGState()

// ── Done ──
image.unlockFocus()

// ─── Export ─────────────────────────────────────────
guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("ERROR: failed to get CGImage")
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
bitmapRep.size = NSSize(width: s, height: s)
guard let pngData = bitmapRep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
    print("ERROR: failed to create PNG")
    exit(1)
}

let outURL = URL(fileURLWithPath: "icon-1024.png")
try pngData.write(to: outURL)
print("✅ Generated icon-1024.png — \(pngData.count) bytes (\(s)×\(s))")
