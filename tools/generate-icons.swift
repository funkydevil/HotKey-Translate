import AppKit
import CoreGraphics
import Foundation

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

private func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
    }

    try data.write(to: url, options: .atomic)
}

private func image(size: CGFloat, draw: (CGContext, CGFloat) -> Void) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    draw(context, size)
    image.unlockFocus()
    return image
}

private func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

private func drawAppIcon(context ctx: CGContext, size: CGFloat) {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.22

    let bg = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(calibratedRed: 0.08, green: 0.20, blue: 0.43, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.07, green: 0.48, blue: 0.78, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.12, green: 0.72, blue: 0.62, alpha: 1).cgColor
        ] as CFArray,
        locations: [0, 0.55, 1]
    )!

    ctx.saveGState()
    ctx.addPath(roundedRect(rect.insetBy(dx: size * 0.035, dy: size * 0.035), radius: corner))
    ctx.clip()
    ctx.drawLinearGradient(bg, start: CGPoint(x: size * 0.12, y: size * 0.95), end: CGPoint(x: size * 0.92, y: size * 0.05), options: [])

    ctx.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.12).cgColor)
    ctx.fillEllipse(in: CGRect(x: size * 0.58, y: size * 0.62, width: size * 0.55, height: size * 0.55))
    ctx.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.08).cgColor)
    ctx.fillEllipse(in: CGRect(x: -size * 0.18, y: -size * 0.12, width: size * 0.54, height: size * 0.54))
    ctx.restoreGState()

    let keyRect = CGRect(x: size * 0.18, y: size * 0.21, width: size * 0.64, height: size * 0.42)
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.018), blur: size * 0.045, color: NSColor(calibratedWhite: 0, alpha: 0.24).cgColor)
    ctx.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.94).cgColor)
    ctx.addPath(roundedRect(keyRect, radius: size * 0.10))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    ctx.setStrokeColor(NSColor(calibratedRed: 0.06, green: 0.31, blue: 0.49, alpha: 0.18).cgColor)
    ctx.setLineWidth(size * 0.016)
    ctx.addPath(roundedRect(keyRect.insetBy(dx: size * 0.018, dy: size * 0.018), radius: size * 0.078))
    ctx.strokePath()

    let bubbleRect = CGRect(x: size * 0.35, y: size * 0.48, width: size * 0.48, height: size * 0.30)
    ctx.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.98).cgColor)
    ctx.addPath(roundedRect(bubbleRect, radius: size * 0.095))
    ctx.fillPath()

    ctx.beginPath()
    ctx.move(to: CGPoint(x: bubbleRect.minX + size * 0.12, y: bubbleRect.minY + size * 0.01))
    ctx.addLine(to: CGPoint(x: bubbleRect.minX + size * 0.18, y: bubbleRect.minY - size * 0.075))
    ctx.addLine(to: CGPoint(x: bubbleRect.minX + size * 0.23, y: bubbleRect.minY + size * 0.02))
    ctx.closePath()
    ctx.fillPath()

    let font = NSFont.systemFont(ofSize: size * 0.24, weight: .bold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(calibratedRed: 0.05, green: 0.31, blue: 0.50, alpha: 1)
    ]
    let text = "A"
    let textSize = text.size(withAttributes: attributes)
    text.draw(
        at: CGPoint(x: keyRect.minX + size * 0.14, y: keyRect.minY + (keyRect.height - textSize.height) * 0.49),
        withAttributes: attributes
    )

    ctx.setStrokeColor(NSColor(calibratedRed: 0.08, green: 0.56, blue: 0.57, alpha: 1).cgColor)
    ctx.setLineWidth(size * 0.035)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    let arrowY = keyRect.midY - size * 0.005
    ctx.move(to: CGPoint(x: keyRect.midX - size * 0.02, y: arrowY))
    ctx.addLine(to: CGPoint(x: keyRect.maxX - size * 0.17, y: arrowY))
    ctx.strokePath()
    ctx.beginPath()
    ctx.move(to: CGPoint(x: keyRect.maxX - size * 0.21, y: arrowY + size * 0.055))
    ctx.addLine(to: CGPoint(x: keyRect.maxX - size * 0.15, y: arrowY))
    ctx.addLine(to: CGPoint(x: keyRect.maxX - size * 0.21, y: arrowY - size * 0.055))
    ctx.strokePath()

    let bubbleFont = NSFont.systemFont(ofSize: size * 0.13, weight: .semibold)
    let bubbleAttributes: [NSAttributedString.Key: Any] = [
        .font: bubbleFont,
        .foregroundColor: NSColor(calibratedRed: 0.06, green: 0.40, blue: 0.60, alpha: 1)
    ]
    let glyph = "Aa"
    let glyphSize = glyph.size(withAttributes: bubbleAttributes)
    glyph.draw(
        at: CGPoint(x: bubbleRect.midX - glyphSize.width * 0.5, y: bubbleRect.midY - glyphSize.height * 0.48),
        withAttributes: bubbleAttributes
    )
}

private func drawStatusIcon(context ctx: CGContext, size: CGFloat) {
    let scale = size / 18
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.setStrokeColor(NSColor.black.cgColor)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let bubble = CGRect(x: 3 * scale, y: 6 * scale, width: 12 * scale, height: 8 * scale)
    ctx.setLineWidth(1.8 * scale)
    ctx.addPath(roundedRect(bubble, radius: 3 * scale))
    ctx.strokePath()

    ctx.beginPath()
    ctx.move(to: CGPoint(x: 7 * scale, y: 6.2 * scale))
    ctx.addLine(to: CGPoint(x: 6 * scale, y: 3.9 * scale))
    ctx.addLine(to: CGPoint(x: 9 * scale, y: 6.1 * scale))
    ctx.strokePath()

    let key = CGRect(x: 3.6 * scale, y: 3.1 * scale, width: 10.8 * scale, height: 5.1 * scale)
    ctx.setLineWidth(1.55 * scale)
    ctx.addPath(roundedRect(key, radius: 1.6 * scale))
    ctx.strokePath()

    ctx.setLineWidth(1.45 * scale)
    ctx.move(to: CGPoint(x: 5.4 * scale, y: 5.55 * scale))
    ctx.addLine(to: CGPoint(x: 7.0 * scale, y: 5.55 * scale))
    ctx.strokePath()

    ctx.move(to: CGPoint(x: 9.1 * scale, y: 5.55 * scale))
    ctx.addLine(to: CGPoint(x: 12.1 * scale, y: 5.55 * scale))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: 11.1 * scale, y: 6.75 * scale))
    ctx.addLine(to: CGPoint(x: 12.45 * scale, y: 5.55 * scale))
    ctx.addLine(to: CGPoint(x: 11.1 * scale, y: 4.35 * scale))
    ctx.strokePath()
}

let appIconDir = root.appendingPathComponent("HotKeyTranslateApp/Assets.xcassets/AppIcon.appiconset")
let statusDir = root.appendingPathComponent("HotKeyTranslateApp/Assets.xcassets/StatusBarIcon.imageset")

let appSizes = [16, 32, 64, 128, 256, 512, 1024]
for size in appSizes {
    try writePNG(image(size: CGFloat(size), draw: drawAppIcon), to: appIconDir.appendingPathComponent("AppIcon-\(size).png"))
}

let statusSizes = [18, 36, 54]
for size in statusSizes {
    try writePNG(image(size: CGFloat(size), draw: drawStatusIcon), to: statusDir.appendingPathComponent("StatusBarIcon-\(size).png"))
}
