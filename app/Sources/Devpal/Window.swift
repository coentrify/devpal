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
    private var persona: Persona?
    private var commands: Commands?
    private var canTalk = false
    private var talking = false
    /// The microphone and the voice share one engine, so echo cancellation knows what is playing.
    private let audio = AVAudioEngine()
    private var answering: Task<Void, Never>?
    private var answerID = 0
    /// After it speaks, the room settles this long before it listens again, so its echo is never taken for you.
    static let echoTail: Duration = .milliseconds(500)
    /// While it speaks it hears only these: saying one stops it at once.
    static let stopWords: [[String]] = [["stop"], ["wait"], ["enough"], ["quiet"], ["pause"], ["hold", "on"], ["hang", "on"], ["shut", "up"]]

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
        self.persona = persona
        let memory = Memory(file: options.memory)
        commands = Commands(memory: memory)
        let brain = Brain(tone: persona.tone, memory: memory, machine: Machine(projects: options.projects))
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
        let id = answerID
        answering = Task {
            var cutter = Sentences()
            var spoken: Task<Void, Never>?
            @MainActor func speak(_ sentence: String) {
                let samples = Task { try? await speech.synthesize(sentence) }
                let before = spoken
                spoken = Task { @MainActor in
                    await before?.value
                    guard let samples = await samples.value, id == answerID else { return }
                    show(.persona(sentence), for: nil)
                    try? await speech.play(samples)
                }
            }
            do {
                let fixed = persona?.fixedReply(to: text) ?? commands?.run(text)
                let reply = fixed.map(Self.just) ?? brain.reply(to: text)
                for try await piece in reply {
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
            try? await Task.sleep(for: Self.echoTail)
            guard id == answerID else { return }
            // What was heard while it spoke is its own echo: it is dropped, and listening starts fresh.
            listener?.discard()
            talking = false
        }
    }

    private static func just(_ text: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.yield(text); $0.finish() }
    }

    /// Stops the answer at once: no more text, no more speech.
    private func interrupt() {
        if talking { trace("interrupted") }
        answerID += 1
        answering?.cancel()
        answering = nil
        speech?.stop()
        talking = false
    }

    /// Whether you said one of the stop words.
    private static func saysStop(_ text: String) -> Bool {
        let heard = text.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        return stopWords.contains { stop in
            heard.indices.contains { start in Array(heard[start...].prefix(stop.count)) == stop }
        }
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
        trace("\(event) talking=\(talking)")
        switch event {
        case .ready: show(.status("Listening"), for: 2)
        case .speaking:
            if !talking { show(.you("..."), for: nil) }
        case .partial(let text):
            if talking {
                // While it speaks, only a stop word gets through: the rest may be its own echo.
                guard Self.saysStop(text) else { return }
                interrupt()
                listener?.discard()
                show(.status("Listening"), for: 3)
                return
            }
            show(.you(text + " ..."), for: nil)
        case .heard(let text):
            guard !talking else { return }
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
