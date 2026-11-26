import AppKit
import MetalKit

/// The companion's window: the screen drawn at 30 frames a second, with
/// what you say shown as subtitles.
@MainActor
final class Window: NSObject, NSApplicationDelegate, MTKViewDelegate {
    static let framesPerSecond = 30
    /// A line of dialogue leaves the screen after this long.
    static let subtitleSeconds: TimeInterval = 8

    private let options: Options
    private var window: NSWindow?
    private var screen: Screen?
    private let start = Date()
    private var listener: Listener?
    private var clearSubtitle: DispatchWorkItem?

    init(options: Options) {
        self.options = options
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: options.width, height: options.height))
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = Self.framesPerSecond
        view.framebufferOnly = true
        do {
            let screen = try Screen(layers: options.layers, targetFormat: view.colorPixelFormat)
            view.device = screen.device
            screen.subtitle = options.subtitle
            self.screen = screen
        } catch {
            fail(error)
        }
        view.delegate = self

        let window = NSWindow(contentRect: view.frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Devpal"
        window.contentView = view
        window.backgroundColor = .black
        window.collectionBehavior = [.fullScreenPrimary]
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.mainMenu = Self.menu()
        NSApp.activate()
        if options.fullScreen { window.toggleFullScreen(nil) }
        if options.listen { startListening() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        listener?.stop()
    }

    private func startListening() {
        show("Loading speech recognition...", for: nil)
        let listener = Listener { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        listener.start()
        self.listener = listener
    }

    private func handle(_ event: Listener.Event) {
        switch event {
        case .ready: show("Listening", for: 2)
        case .speaking: show("...", for: nil)
        case .heard(let text): show(text, for: Self.subtitleSeconds)
        case .failed(let reason):
            FileHandle.standardError.write(Data("devpal: listening failed: \(reason)\n".utf8))
            show("Cannot listen: \(reason)", for: nil)
        }
    }

    private func show(_ text: String, for seconds: TimeInterval?) {
        screen?.subtitle = text
        clearSubtitle?.cancel()
        guard let seconds else { return }
        let clear = DispatchWorkItem { [weak self] in self?.screen?.subtitle = "" }
        clearSubtitle = clear
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: clear)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let screen, let drawable = view.currentDrawable, let commandBuffer = screen.queue.makeCommandBuffer() else { return }
        screen.encode(into: drawable.texture, time: Float(Date().timeIntervalSince(start)), commandBuffer: commandBuffer)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private static func menu() -> NSMenu {
        let app = NSMenu()
        app.addItem(withTitle: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
            .keyEquivalentModifierMask = [.command, .control]
        app.addItem(.separator())
        app.addItem(withTitle: "Quit Devpal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let item = NSMenuItem()
        item.submenu = app
        let bar = NSMenu()
        bar.addItem(item)
        return bar
    }
}

func fail(_ error: Error) -> Never {
    FileHandle.standardError.write(Data("devpal: \(error)\n".utf8))
    exit(1)
}
