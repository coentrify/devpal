import AppKit
import Metal

/// Renders a line of dialogue into a texture: light text on a dark band,
/// wrapped to the width it is given.
enum Subtitles {
    /// The subtitles take this share of the screen's width.
    static let width: Float = 0.78
    /// Their bottom edge sits this far above the bottom of the screen.
    static let margin: Float = 0.08
    /// The text height as a share of the screen's height.
    static let fontShare: CGFloat = 0.042

    static func texture(_ text: String, screenWidth: Int, screenHeight: Int, device: MTLDevice) -> MTLTexture? {
        let width = max(Int(Float(screenWidth) * Self.width), 64)
        let fontSize = max(CGFloat(screenHeight) * fontShare, 12)
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(red: 0.16, green: 0.96, blue: 1, alpha: 0.8)
        shadow.shadowBlurRadius = fontSize * 0.35
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph,
            .shadow: shadow,
        ])
        let padding = fontSize * 0.6
        let bounds = attributed.boundingRect(
            with: NSSize(width: CGFloat(width) - 2 * padding, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let height = Int(ceil(bounds.height + 2 * padding))
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            let band = NSRect(x: 0, y: 0, width: width, height: height)
            NSColor(red: 0.01, green: 0, blue: 0.04, alpha: 0.88).setFill()
            NSBezierPath(roundedRect: band, xRadius: padding * 0.5, yRadius: padding * 0.5).fill()
            attributed.draw(with: band.insetBy(dx: padding, dy: padding), options: [.usesLineFragmentOrigin, .usesFontLeading])
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
        guard drawn else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: bytesPerRow)
        return texture
    }
}
