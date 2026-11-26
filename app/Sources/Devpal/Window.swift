import AppKit
import MetalKit

/// The companion's window: the screen drawn at 60 frames a second, with
/// what you say shown as subtitles.
@MainActor
final class Window: NSObject, NSApplicationDelegate, MTKViewDelegate {
    static let framesPerSecond = 60
    /// A line of dialogue leaves the screen after this long.
    static let subtitleSeconds: TimeInterval = 8

    private let options: Options
    private var window: NSWindow?
    private var screen: Screen?
    private let start = Date()
    private var listener: Listener?
    private var clearSubtitle: DispatchWorkItem?
    private var brain: Brain?
    private var speech: Speech?
    private var canTalk = false
    private var talking = false
    /// After it speaks, the room settles this long before it listens again.
    static let echoTail: Duration = .milliseconds(300)

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
            if !options.subtitle.isEmpty { screen.subtitle = .persona(options.subtitle) }
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
        if options.talk { startTalking() }
        if options.listen { startListening() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        listener?.stop()
        brain?.stop()
    }

    private func startTalking() {
        let persona: Persona
        do {
            persona = try Persona(folder: options.layers.persona)
        } catch {
            report("cannot talk: \(error)")
            return
        }
        let brain = Brain(tone: persona.tone)
        let speech = Speech(voice: persona.voice)
        self.brain = brain
        self.speech = speech
        Task {
            do {
                try await brain.start()
                try await speech.load()
                canTalk = true
            } catch {
                report("cannot talk: \(error)")
            }
        }
    }

    /// Answers what you said, sentence by sentence: each is spoken and shown as soon as it is ready.
    private func answer(_ text: String) {
        guard canTalk, !talking, let brain, let speech else { return }
        talking = true
        listener?.muted = true
        Task {
            var cutter = Sentences()
            var spoken: Task<Void, Never>?
            func speak(_ sentence: String) {
                let samples = Task { try? await speech.synthesize(sentence) }
                let before = spoken
                spoken = Task { @MainActor in
                    await before?.value
                    guard let samples = await samples.value else { return }
                    show(.persona(sentence), for: nil)
                    try? await speech.play(samples)
                }
            }
            do {
                for try await piece in brain.reply(to: text) {
                    for sentence in cutter.add(piece) { speak(sentence) }
                }
                if let last = cutter.rest() { speak(last) }
            } catch {
                report("cannot answer: \(error)")
            }
            await spoken?.value
            try? await Task.sleep(for: Self.echoTail)
            if case .persona = screen?.subtitle.who { show(screen!.subtitle, for: Self.subtitleSeconds) }
            listener?.muted = false
            talking = false
        }
    }

    private func report(_ message: String) {
        FileHandle.standardError.write(Data("devpal: \(message)\n".utf8))
        show(.status(message), for: nil)
    }

    private func startListening() {
        show(.status("Loading speech recognition..."), for: nil)
        let listener = Listener { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        listener.start()
        self.listener = listener
    }

    private func handle(_ event: Listener.Event) {
        switch event {
        case .ready: show(.status("Listening"), for: 2)
        case .speaking: show(.you("..."), for: nil)
        case .partial(let text): show(.you(text + " ..."), for: nil)
        case .heard(let text):
            show(.you(text), for: Self.subtitleSeconds)
            answer(text)
        case .failed(let reason): report("cannot listen: \(reason)")
        }
    }

    private func show(_ line: Line, for seconds: TimeInterval?) {
        screen?.subtitle = line
        clearSubtitle?.cancel()
        guard let seconds else { return }
        let clear = DispatchWorkItem { [weak self] in self?.screen?.subtitle = .none }
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
