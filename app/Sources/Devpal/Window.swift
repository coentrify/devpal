import AVFoundation
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
    /// The microphone and the voice share one engine, so echo cancellation knows what is playing.
    private let audio = AVAudioEngine()
    private var answering: Task<Void, Never>?
    private var answerID = 0
    /// What it said in its last answer, to tell its own echo from you.
    private var said: Set<String> = []
    private var quietSince = Date.distantPast
    /// Words heard this soon after it stops speaking may still be its own echo.
    static let echoTail: TimeInterval = 2.5
    /// Set when you stop it, so what you say next is answered.
    private var youInterrupted = false
    /// Heard words are its own echo when at least this share of them is what it just said.
    static let echoShare = 0.5
    /// It stops for you once it hears this many words of yours.
    static let interruptWords = 2

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
        let brain = Brain(tone: persona.tone, memory: Memory(file: options.memory), machine: Machine(projects: options.projects))
        let speech = Speech(voice: persona.voice, engine: audio)
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
        guard canTalk, let brain, let speech else { return }
        interrupt()
        talking = true
        said = []
        let id = answerID
        answering = Task {
            var cutter = Sentences()
            var spoken: Task<Void, Never>?
            @MainActor func speak(_ sentence: String) {
                said.formUnion(Self.words(sentence))
                let samples = Task { try? await speech.synthesize(sentence) }
                let before = spoken
                spoken = Task { @MainActor in
                    await before?.value
                    guard let samples = await samples.value, id == answerID else { return }
                    show(.persona(sentence), for: nil)
                    listener?.companionSpeaking = true
                    try? await speech.play(samples)
                }
            }
            do {
                for try await piece in brain.reply(to: text) {
                    for sentence in cutter.add(piece) { speak(sentence) }
                }
                if let last = cutter.rest() { speak(last) }
            } catch is CancellationError {
            } catch {
                if id == answerID { report("cannot answer: \(error)") }
            }
            await spoken?.value
            guard id == answerID else { return }
            if case .persona = screen?.subtitle.who { show(screen!.subtitle, for: Self.subtitleSeconds) }
            talking = false
            listener?.companionSpeaking = false
            quietSince = Date()
        }
    }

    /// Stops the answer at once: no more text, no more speech.
    private func interrupt() {
        if talking { trace("interrupted") }
        answerID += 1
        answering?.cancel()
        answering = nil
        speech?.stop()
        if talking { quietSince = Date() }
        talking = false
        listener?.companionSpeaking = false
    }

    /// Words heard while it speaks, or just after, that are mostly what it said are its own echo.
    private func isEcho(_ text: String) -> Bool {
        guard talking || Date().timeIntervalSince(quietSince) < Self.echoTail else { return false }
        let heard = Self.words(text)
        guard !heard.isEmpty else { return true }
        return Double(heard.intersection(said).count) / Double(heard.count) >= Self.echoShare
    }

    nonisolated private static func words(_ text: String) -> Set<String> {
        Set(text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
    }

    private func report(_ message: String) {
        FileHandle.standardError.write(Data("devpal: \(message)\n".utf8))
        show(.status(message), for: nil)
    }

    private func startListening() {
        show(.status("Loading speech recognition..."), for: nil)
        let listener = Listener(engine: audio) { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        listener.start()
        self.listener = listener
    }

    /// With DEVPAL_DEBUG=1, what it hears and does goes to standard error, and nowhere else.
    private static let debug = ProcessInfo.processInfo.environment["DEVPAL_DEBUG"] == "1"

    private func trace(_ message: @autoclosure () -> String) {
        if Self.debug { FileHandle.standardError.write(Data("devpal debug: \(message())\n".utf8)) }
    }

    private func handle(_ event: Listener.Event) {
        trace("\(event) talking=\(talking) echo=\(isEcho("\(event)"))")
        switch event {
        case .ready: show(.status("Listening"), for: 2)
        case .speaking:
            if !talking { show(.you("..."), for: nil) }
        case .partial(let text):
            if talking {
                // It stops for you once your words are clear and louder than its own echo.
                guard !isEcho(text), Self.words(text).count >= Self.interruptWords, listener?.louderThanEcho == true else { return }
                interrupt()
                youInterrupted = true
            } else if !youInterrupted, isEcho(text) {
                return
            }
            show(.you(text + " ..."), for: nil)
        case .heard(let text):
            // While it speaks, only what stopped it is you: the rest is its own echo.
            if talking { return }
            if !youInterrupted, isEcho(text) { return }
            youInterrupted = false
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
