import AppKit
import Foundation

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let statusDir = root.appendingPathComponent("HotKeyTranslateApp/Assets.xcassets/StatusBarIcon.imageset")

private func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "StatusIconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
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

    context.clear(CGRect(x: 0, y: 0, width: size, height: size))
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    draw(context, size)
    image.unlockFocus()
    return image
}

private func drawCentered(_ string: String, font: NSFont, in rect: CGRect) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.black
    ]
    let textSize = string.size(withAttributes: attributes)
    let origin = CGPoint(
        x: rect.midX - textSize.width / 2,
        y: rect.midY - textSize.height / 2 - font.descender * 0.18
    )
    string.draw(at: origin, withAttributes: attributes)
}

private func drawStatusIcon(context ctx: CGContext, size: CGFloat) {
    let scale = size / 18
    let latinFont = NSFont(name: "HelveticaNeue-Bold", size: 10.3 * scale)
        ?? NSFont.systemFont(ofSize: 10.3 * scale, weight: .bold)
    let cjkFont = NSFont(name: "HiraginoSans-W6", size: 10.9 * scale)
        ?? NSFont.systemFont(ofSize: 10.9 * scale, weight: .semibold)

    let leftRect = CGRect(x: 0.6 * scale, y: 1.4 * scale, width: 8.2 * scale, height: 15.0 * scale)
    let rightRect = CGRect(x: 8.4 * scale, y: 1.4 * scale, width: 9.0 * scale, height: 15.0 * scale)

    drawCentered("A", font: latinFont, in: leftRect)
    drawCentered("文", font: cjkFont, in: rightRect)
}

for size in [18, 36, 54] {
    try writePNG(
        image(size: CGFloat(size), draw: drawStatusIcon),
        to: statusDir.appendingPathComponent("StatusBarIcon-\(size).png")
    )
}
