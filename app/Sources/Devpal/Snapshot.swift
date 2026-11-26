import AppKit
import Metal

/// Renders one frame offscreen and writes it to a PNG file.
enum Snapshot {
    static func write(_ options: Options, to file: URL) throws {
        let screen = try Screen(layers: options.layers, targetFormat: .bgra8Unorm)
        screen.subtitle = options.subtitle
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: options.width, height: options.height, mipmapped: false)
        descriptor.usage = .renderTarget
        descriptor.storageMode = .shared
        guard let target = screen.device.makeTexture(descriptor: descriptor),
              let commandBuffer = screen.queue.makeCommandBuffer() else { throw ScreenError.noMetal }
        screen.encode(into: target, time: options.time, commandBuffer: commandBuffer)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let bytesPerRow = options.width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * options.height)
        target.getBytes(&bytes, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, options.width, options.height), mipmapLevel: 0)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: options.width, pixelsHigh: options.height, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: bytesPerRow, bitsPerPixel: 32
        ), let pixels = rep.bitmapData else { throw ScreenError.snapshotFailed(file.path) }
        for index in stride(from: 0, to: bytes.count, by: 4) {
            pixels[index] = bytes[index + 2]
            pixels[index + 1] = bytes[index + 1]
            pixels[index + 2] = bytes[index]
            pixels[index + 3] = 255
        }
        guard let png = rep.representation(using: .png, properties: [:]) else { throw ScreenError.snapshotFailed(file.path) }
        try png.write(to: file)
    }
}
