import AppKit

func generateIconImage(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    let rect = NSRect(x: size * 0.1, y: size * 0.08, width: size * 0.8, height: size * 0.84)
    let cornerRadius = size * 0.16

    // Shadow
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.04)
    shadow.shadowBlurRadius = size * 0.08
    shadow.set()

    // Notepad Page Base (Crisp white / subtle gradient)
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.97, alpha: 1.0)
    )!
    gradient.draw(in: path, angle: -90)

    // Reset shadow for internal drawing
    NSShadow().set()

    // Border
    NSColor(calibratedWhite: 0.85, alpha: 1.0).setStroke()
    path.lineWidth = max(1.0, size * 0.015)
    path.stroke()

    // Top Header Bar (Notepad binding header - sleek Windows/Notepad cyan-blue)
    let headerHeight = size * 0.18
    let headerRect = NSRect(x: rect.minX, y: rect.maxY - headerHeight, width: rect.width, height: headerHeight)

    // Clip to main path to keep round corners at the top
    NSGraphicsContext.current?.saveGraphicsState()
    path.addClip()
    let headerGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.12, green: 0.53, blue: 0.90, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.05, green: 0.40, blue: 0.78, alpha: 1.0)
    )!
    headerGrad.draw(in: headerRect, angle: -90)

    // Spiral/Binding holes or dots in header
    let dotCount = 5
    let dotRadius = size * 0.02
    let dotSpacing = rect.width / CGFloat(dotCount + 1)
    NSColor(calibratedWhite: 0.3, alpha: 0.4).setFill()
    for i in 1...dotCount {
        let dotCenter = NSPoint(x: rect.minX + dotSpacing * CGFloat(i), y: headerRect.midY)
        let dotPath = NSBezierPath(ovalIn: NSRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        dotPath.fill()
    }
    NSGraphicsContext.current?.restoreGraphicsState()

    // Text Lines on the pad
    let lineCount = 4
    let lineSpacing = size * 0.09
    let startY = rect.minY + size * 0.22
    let lineMargin = size * 0.08

    for i in 0..<lineCount {
        let y = startY + CGFloat(i) * lineSpacing
        let linePath = NSBezierPath()
        let lineWidthFactor: CGFloat = (i == 0) ? 0.45 : (i == 1 ? 0.65 : (i == 2 ? 0.55 : 0.4))
        linePath.move(to: NSPoint(x: rect.minX + lineMargin, y: y))
        linePath.line(to: NSPoint(x: rect.minX + lineMargin + (rect.width - lineMargin * 2) * lineWidthFactor, y: y))
        linePath.lineWidth = max(1.5, size * 0.025)
        linePath.lineCapStyle = .round
        NSColor(calibratedRed: 0.60, green: 0.65, blue: 0.72, alpha: 0.7).setStroke()
        linePath.stroke()
    }

    // Ice Badge / Crystal accent on bottom right
    let badgeSize = size * 0.26
    let badgeRect = NSRect(x: rect.maxX - badgeSize - size * 0.04, y: rect.minY + size * 0.04, width: badgeSize, height: badgeSize)
    let badgePath = NSBezierPath(ovalIn: badgeRect)
    let badgeGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.0, green: 0.75, blue: 0.95, alpha: 0.95),
        ending: NSColor(calibratedRed: 0.0, green: 0.48, blue: 0.85, alpha: 0.95)
    )!
    badgeGrad.draw(in: badgePath, angle: -45)

    // Letter 'i' or 'N' inside badge
    let font = NSFont.systemFont(ofSize: badgeSize * 0.58, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let str = NSAttributedString(string: "N", attributes: attrs)
    let strSize = str.size()
    str.draw(at: NSPoint(x: badgeRect.midX - strSize.width / 2, y: badgeRect.midY - strSize.height / 2))

    img.unlockFocus()
    return img
}

let iconsetDir = "build/iceNotePad.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (baseSize, scale) in sizes {
    let actualSize = CGFloat(baseSize * scale)
    let image = generateIconImage(size: actualSize)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        continue
    }

    let fileName: String
    if scale == 1 {
        fileName = "icon_\(baseSize)x\(baseSize).png"
    } else {
        fileName = "icon_\(baseSize)x\(baseSize)@\(scale)x.png"
    }

    let filePath = "\(iconsetDir)/\(fileName)"
    try? png.write(to: URL(fileURLWithPath: filePath))
}

print("Iconset created successfully.")

