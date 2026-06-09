import AppKit

// ─── Color Palette ───
let bgStart = NSColor(calibratedRed: 0.25, green: 0.55, blue: 0.95, alpha: 1.0)   // blue
let bgEnd   = NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 1.0)   // darker blue
let clipColor    = NSColor(calibratedRed: 0.85, green: 0.87, blue: 0.90, alpha: 1.0)
let clipShadow   = NSColor(calibratedRed: 0.50, green: 0.52, blue: 0.55, alpha: 0.6)
let clockFace    = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.92)
let clockBorder  = NSColor(calibratedRed: 0.20, green: 0.20, blue: 0.22, alpha: 0.5)
let handColor    = NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.18, alpha: 0.85)
let tickColor    = NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.28, alpha: 0.6)
let centerDot    = NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 1.0)

let size = CGSize(width: 1024, height: 1024)
let scale: CGFloat = 1.0
let rect = CGRect(origin: .zero, size: size)
let inset: CGFloat = 30

// ─── Clipboard Body ───
let bodyRect = CGRect(x: inset, y: inset + 20, width: size.width - inset * 2, height: size.height - inset * 2 - 20)
let bodyRadius: CGFloat = 90

let image = NSImage(size: size)
image.lockFocus()

// Background gradient
let gradient = NSGradient(starting: bgStart, ending: bgEnd)!
gradient.draw(in: bodyRect, angle: -45)

// Body shadow (inner glow)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
shadow.shadowBlurRadius = 12
shadow.shadowOffset = NSSize(width: 2, height: -4)
shadow.set()

// Draw body with rounded rect
let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: bodyRadius, yRadius: bodyRadius)
bodyPath.fill()

// Subtle inner highlight
NSColor.white.withAlphaComponent(0.08).setStroke()
bodyPath.lineWidth = 2
bodyPath.stroke()

// ─── Paper lines on clipboard ───
let textInsetX: CGFloat = bodyRect.minX + 80
let lineCenterY: CGFloat = bodyRect.midY + 30
let lineColors = [
    NSColor.white.withAlphaComponent(0.25),
    NSColor.white.withAlphaComponent(0.15),
    NSColor.white.withAlphaComponent(0.20),
    NSColor.white.withAlphaComponent(0.10),
    NSColor.white.withAlphaComponent(0.18),
]
for i in 0..<5 {
    let y = lineCenterY - CGFloat(i) * 40 + 40
    let lineWidth: CGFloat = (i == 0 || i == 2) ? bodyRect.width - 160 : bodyRect.width - 200
    let linePath = NSBezierPath()
    linePath.move(to: NSPoint(x: textInsetX, y: y))
    linePath.line(to: NSPoint(x: textInsetX + lineWidth, y: y))
    lineColors[i % lineColors.count].setStroke()
    linePath.lineWidth = 3
    linePath.stroke()
}

// ─── Clock face ───
let clockDiameter: CGFloat = 260
let clockRect = CGRect(
    x: bodyRect.midX - clockDiameter / 2,
    y: bodyRect.minY + 50,
    width: clockDiameter,
    height: clockDiameter
)

// Clock circle
let clockPath = NSBezierPath(ovalIn: clockRect)
clockFace.setFill()
clockPath.fill()

clockBorder.setStroke()
clockPath.lineWidth = 6
clockPath.stroke()

// Clock ticks (12 positions)
let center = NSPoint(x: clockRect.midX, y: clockRect.midY)
let tickRadiusOuter: CGFloat = clockDiameter / 2 - 14
let tickRadiusInner: CGFloat = clockDiameter / 2 - 30
let tickRadiusInnerSmall: CGFloat = clockDiameter / 2 - 22

for i in 0..<12 {
    let angle = CGFloat(i) * .pi / 6 - .pi / 2
    let isMain = i % 3 == 0
    let innerR = isMain ? tickRadiusInner : tickRadiusInnerSmall
    let p1 = NSPoint(x: center.x + cos(angle) * innerR, y: center.y + sin(angle) * innerR)
    let p2 = NSPoint(x: center.x + cos(angle) * tickRadiusOuter, y: center.y + sin(angle) * tickRadiusOuter)
    let tickPath = NSBezierPath()
    tickPath.move(to: p1)
    tickPath.line(to: p2)
    tickColor.setStroke()
    tickPath.lineWidth = isMain ? 7 : 3.5
    tickPath.stroke()
}

// Hour hand (pointing to ~10:10 for aesthetic look)
let hourAngle: CGFloat = -50 * .pi / 180  // ~10 o'clock
let hourLen: CGFloat = clockDiameter * 0.25
let hourPath = NSBezierPath()
hourPath.move(to: center)
let hourEnd = NSPoint(x: center.x + cos(hourAngle) * hourLen, y: center.y + sin(hourAngle) * hourLen)
hourPath.line(to: hourEnd)
handColor.setStroke()
hourPath.lineWidth = 16
hourPath.lineCapStyle = .round
hourPath.stroke()

// Minute hand (pointing to ~10:10, minute at ~2)
let minAngle: CGFloat = 10 * .pi / 180
let minLen: CGFloat = clockDiameter * 0.38
let minPath = NSBezierPath()
minPath.move(to: center)
let minEnd = NSPoint(x: center.x + cos(minAngle) * minLen, y: center.y + sin(minAngle) * minLen)
minPath.line(to: minEnd)
handColor.setStroke()
minPath.lineWidth = 10
minPath.lineCapStyle = .round
minPath.stroke()

// Center dot
let dotRect = CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28)
let dotPath = NSBezierPath(ovalIn: dotRect)
centerDot.setFill()
dotPath.fill()
NSColor.white.setStroke()
dotPath.lineWidth = 3
dotPath.stroke()

// ─── Clip at top ───
let clipWidth: CGFloat = 100
let clipHeight: CGFloat = 60
let clipX = bodyRect.midX - clipWidth / 2
let clipY = bodyRect.maxY - 6

let clipPath = NSBezierPath()
clipPath.move(to: NSPoint(x: clipX, y: clipY))
clipPath.line(to: NSPoint(x: clipX, y: clipY + clipHeight))
clipPath.curve(
    to: NSPoint(x: clipX + clipWidth, y: clipY + clipHeight),
    controlPoint1: NSPoint(x: clipX + 10, y: clipY + clipHeight + 20),
    controlPoint2: NSPoint(x: clipX + clipWidth - 10, y: clipY + clipHeight + 20)
)
clipPath.line(to: NSPoint(x: clipX + clipWidth, y: clipY))
clipPath.line(to: NSPoint(x: clipX + clipWidth - 12, y: clipY - 8))
clipPath.line(to: NSPoint(x: clipX + 12, y: clipY - 8))
clipPath.close()

clipColor.setFill()
clipPath.fill()

clipShadow.setStroke()
clipPath.lineWidth = 3
clipPath.stroke()

// ─── light reflection/gloss ───
let glossPath = NSBezierPath(roundedRect: bodyRect, xRadius: bodyRadius, yRadius: bodyRadius)
let glossGradient = NSGradient(
    starting: NSColor.white.withAlphaComponent(0.12),
    ending: NSColor.white.withAlphaComponent(0.0)
)!
glossGradient.draw(in: glossPath, angle: 90)

image.unlockFocus()

// ─── Save 1024x1024 PNG ───
guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("ERROR: failed to get CGImage")
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
bitmapRep.size = size
guard let pngData = bitmapRep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
    print("ERROR: failed to create PNG data")
    exit(1)
}

let outputURL = URL(fileURLWithPath: "icon-1024.png")
try pngData.write(to: outputURL)
print("✅ Saved icon-1024.png (\(pngData.count) bytes)")
