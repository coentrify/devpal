import AppKit
import Metal

/// Draws the three layers: the background, then the persona's still on top,
/// into a scene texture that the filter draws to the target.
final class Screen {
    struct Frame {
        var size: SIMD2<Float>
        var time: Float
        var padding: Float = 0
        var personaRect: SIMD4<Float>
    }

    static let sceneFormat = MTLPixelFormat.bgra8Unorm
    /// The persona's still fills this share of the screen's height.
    static let personaHeight: Float = 0.82
    /// The persona stands on the bottom edge, its still this far below it.
    static let personaSink: Float = 0.04

    let device: MTLDevice
    let queue: MTLCommandQueue
    private let backgroundPipeline: MTLRenderPipelineState
    private let personaPipeline: MTLRenderPipelineState
    private let filterPipeline: MTLRenderPipelineState
    private let still: MTLTexture
    private var scene: MTLTexture?
    private var subtitleTexture: MTLTexture?
    private var subtitleKey: (line: Line, width: Int, height: Int)?

    /// The line of dialogue on screen, or none.
    var subtitle = Line.none
    /// A small label at the top of the screen, such as the project in focus, or nothing.
    var label = ""
    private var labelTexture: MTLTexture?
    private var labelKey: (text: String, width: Int, height: Int)?

    init(layers: Layers, targetFormat: MTLPixelFormat) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw ScreenError.noMetal
        }
        if let missing = layers.missingFile() { throw ScreenError.missingFile(missing.path) }
        self.device = device
        self.queue = queue

        guard let passes = Bundle.module.url(forResource: "screen", withExtension: "metal", subdirectory: "Shaders") else {
            throw ScreenError.missingFile("screen.metal")
        }
        let source = try [
            "#include <metal_stdlib>\nusing namespace metal;\n",
            String(contentsOf: layers.backgroundShader, encoding: .utf8),
            String(contentsOf: layers.filterShader, encoding: .utf8),
            String(contentsOf: passes, encoding: .utf8),
        ].joined(separator: "\n")
        let library = try device.makeLibrary(source: source, options: nil)

        func pipeline(_ vertex: String, _ fragment: String, _ format: MTLPixelFormat, blended: Bool) throws -> MTLRenderPipelineState {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: vertex)
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            let attachment = descriptor.colorAttachments[0]!
            attachment.pixelFormat = format
            if blended {
                attachment.isBlendingEnabled = true
                attachment.sourceRGBBlendFactor = .one
                attachment.sourceAlphaBlendFactor = .one
                attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
                attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
            return try device.makeRenderPipelineState(descriptor: descriptor)
        }
        backgroundPipeline = try pipeline("fullscreen_vertex", "background_fragment", Self.sceneFormat, blended: false)
        personaPipeline = try pipeline("persona_vertex", "persona_fragment", Self.sceneFormat, blended: true)
        filterPipeline = try pipeline("fullscreen_vertex", "filter_fragment", targetFormat, blended: false)
        still = try Self.texture(svg: layers.personaIdleStill, device: device)
    }

    /// Encodes one frame into the target texture.
    func encode(into target: MTLTexture, time: Float, commandBuffer: MTLCommandBuffer) {
        let scene = sceneTexture(width: target.width, height: target.height)
        var frame = Frame(size: SIMD2(Float(target.width), Float(target.height)), time: time, personaRect: personaRect(target))

        let scenePass = MTLRenderPassDescriptor()
        scenePass.colorAttachments[0].texture = scene
        scenePass.colorAttachments[0].loadAction = .dontCare
        scenePass.colorAttachments[0].storeAction = .store
        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: scenePass) {
            encoder.setRenderPipelineState(backgroundPipeline)
            encoder.setFragmentBytes(&frame, length: MemoryLayout<Frame>.stride, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.setRenderPipelineState(personaPipeline)
            encoder.setVertexBytes(&frame, length: MemoryLayout<Frame>.stride, index: 0)
            encoder.setFragmentTexture(still, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            if let texture = labelTexture(width: target.width, height: target.height) {
                var band = frame
                band.personaRect = labelRect(texture, target)
                encoder.setVertexBytes(&band, length: MemoryLayout<Frame>.stride, index: 0)
                encoder.setFragmentTexture(texture, index: 0)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }
            if let texture = subtitleTexture(width: target.width, height: target.height) {
                var band = frame
                band.personaRect = subtitleRect(texture, target)
                encoder.setVertexBytes(&band, length: MemoryLayout<Frame>.stride, index: 0)
                encoder.setFragmentTexture(texture, index: 0)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }
            encoder.endEncoding()
        }

        let filterPass = MTLRenderPassDescriptor()
        filterPass.colorAttachments[0].texture = target
        filterPass.colorAttachments[0].loadAction = .dontCare
        filterPass.colorAttachments[0].storeAction = .store
        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: filterPass) {
            encoder.setRenderPipelineState(filterPipeline)
            encoder.setFragmentBytes(&frame, length: MemoryLayout<Frame>.stride, index: 0)
            encoder.setFragmentTexture(scene, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }
    }

    /// The persona's still keeps its aspect, centered, standing on the bottom edge.
    private func personaRect(_ target: MTLTexture) -> SIMD4<Float> {
        let height = Self.personaHeight
        let width = height * Float(still.width) / Float(still.height) * Float(target.height) / Float(target.width)
        return SIMD4((1 - width) / 2, 1 - height + Self.personaSink, width, height)
    }

    /// The subtitles are centered, above the bottom edge, drawn before the filter so it lies over them too.
    private func subtitleRect(_ texture: MTLTexture, _ target: MTLTexture) -> SIMD4<Float> {
        let width = Float(texture.width) / Float(target.width)
        let height = Float(texture.height) / Float(target.height)
        return SIMD4((1 - width) / 2, 1 - Subtitles.margin - height, width, height)
    }

    /// The label sits at the top left, inside the curve of the filter.
    private func labelRect(_ texture: MTLTexture, _ target: MTLTexture) -> SIMD4<Float> {
        SIMD4(Subtitles.labelMargin, Subtitles.labelMargin, Float(texture.width) / Float(target.width), Float(texture.height) / Float(target.height))
    }

    private func labelTexture(width: Int, height: Int) -> MTLTexture? {
        guard !label.isEmpty else { return nil }
        if let key = labelKey, key.text == label, key.width == width, key.height == height { return labelTexture }
        labelTexture = Subtitles.texture(.status(label), screenWidth: width, screenHeight: height, device: device, fontShare: Subtitles.labelFontShare, fit: true)
        labelKey = (label, width, height)
        return labelTexture
    }

    private func subtitleTexture(width: Int, height: Int) -> MTLTexture? {
        var line = subtitle
        line.text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.text.isEmpty else { return nil }
        if let key = subtitleKey, key.line == line, key.width == width, key.height == height { return subtitleTexture }
        subtitleTexture = Subtitles.texture(line, screenWidth: width, screenHeight: height, device: device)
        subtitleKey = (line, width, height)
        return subtitleTexture
    }

    private func sceneTexture(width: Int, height: Int) -> MTLTexture {
        if let scene, scene.width == width, scene.height == height { return scene }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Self.sceneFormat, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        let texture = device.makeTexture(descriptor: descriptor)!
        scene = texture
        return texture
    }

    /// Rasterizes an SVG still into a premultiplied texture.
    static func texture(svg: URL, device: MTLDevice, pixels: Int = 1600) throws -> MTLTexture {
        guard let image = NSImage(contentsOf: svg), image.size.width > 0, image.size.height > 0 else {
            throw ScreenError.unreadableStill(svg.path)
        }
        let width = pixels
        let height = Int((Double(pixels) * image.size.height / image.size.width).rounded())
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            image.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
        guard drawn else { throw ScreenError.unreadableStill(svg.path) }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else { throw ScreenError.noMetal }
        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: bytesPerRow)
        return texture
    }
}

enum ScreenError: Error, CustomStringConvertible {
    case noMetal, missingFile(String), unreadableStill(String), snapshotFailed(String)

    var description: String {
        switch self {
        case .noMetal: "this machine has no Metal device"
        case .missingFile(let path): "missing \(path)"
        case .unreadableStill(let path): "cannot read the still \(path)"
        case .snapshotFailed(let path): "cannot write the snapshot \(path)"
        }
    }
}
