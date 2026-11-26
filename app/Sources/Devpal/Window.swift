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
    private var conversation: Conversation?
    private var canTalk = false
    private var talking = false
    /// The microphone and the voice share one engine, so echo cancellation knows what is playing.
    private let audio = AVAudioEngine()
    private var answering: Task<Void, Never>?
    private var answerID = 0
    /// After it speaks, the room settles this long before it listens again, so its echo is never taken for you.
    static let echoTail: Duration = .milliseconds(800)
    /// While it speaks it hears only these: saying one stops it at once.
    static let stopWords: [[String]] = [["stop"], ["enough"], ["quiet"], ["shut", "up"]]
    /// Saying one holds everything, its speech and its answering, until you say continue.
    static let pauseWords: [[String]] = [["pause"], ["wait"], ["hold", "on"], ["hang", "on"]]
    static let continueWords: [[String]] = [["continue"], ["resume"], ["go", "on"], ["carry", "on"]]
    /// While paused, it hears only the continue words.
    private var paused = false

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
        let memory = Memory(file: options.memory)
        let agents = Agents(projects: options.projects)
        let brain = Brain(tone: persona.tone, memory: memory, agents: agents)
        let conversation = Conversation(persona: persona, memory: memory, brain: brain, agents: agents)
        conversation.onAnnounce = { [weak self] text in self?.announce(text) }
        conversation.onFocus = { [weak self] project in self?.screen?.label = project.map { "// \($0.uppercased())" } ?? "" }
        self.conversation = conversation
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

    /// Answers what you said.
    private func answer(_ text: String) {
        guard canTalk, let conversation else { return }
        say(conversation.reply(to: text))
    }

    /// Says something on its own, such as an agent's report, once it is not talking.
    private func announce(_ text: String) {
        Task {
            while talking { try? await Task.sleep(for: .milliseconds(300)) }
            say(Conversation.just(text))
        }
    }

    /// Speaks a reply sentence by sentence: each is spoken and shown as soon as it is ready.
    private func say(_ reply: AsyncThrowingStream<String, Error>) {
        guard let speech else { return }
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

    /// Stops the answer at once: no more text, no more speech.
    private func interrupt() {
        if talking { trace("interrupted") }
        answerID += 1
        answering?.cancel()
        answering = nil
        speech?.stop()
        talking = false
    }

    /// Whether you said one of the phrases, word for word.
    private static func says(_ phrases: [[String]], in text: String) -> Bool {
        let heard = Persona.words(text)
        return phrases.contains { phrase in
            heard.indices.contains { start in Array(heard[start...].prefix(phrase.count)) == phrase }
        }
    }

    private func report(_ message: String) {
        FileHandle.standardError.write(Data("devpal: \(message)\n".utf8))
        show(.status(message), for: nil)
    }

    private func startListening() {
        show(.status("Loading speech recognition..."), for: nil)
        let listener = Listener(engine: audio) { [weak self] event, generation in
            Task { @MainActor in self?.handle(event, generation: generation) }
        }
        listener.start()
        self.listener = listener
    }

    /// With DEVPAL_DEBUG=1, what it hears and does goes to standard error, and nowhere else.
    private static let debug = ProcessInfo.processInfo.environment["DEVPAL_DEBUG"] == "1"

    private func trace(_ message: @autoclosure () -> String) {
        if Self.debug { FileHandle.standardError.write(Data("devpal debug: \(message())\n".utf8)) }
    }

    private func handle(_ event: Listener.Event, generation: Int) {
        trace("\(event) talking=\(talking) paused=\(paused) stale=\(listener?.isStale(generation) ?? false)")
        switch event {
        case .ready: show(.status("Listening"), for: 2)
        case .failed(let reason): report("cannot listen: \(reason)")
        case .speaking, .partial, .heard:
            // Audio from before it went quiet may hold its own voice: it was dropped, and so are its events.
            guard listener?.isStale(generation) != true else { return }
            listen(to: event)
        }
    }

    private func listen(to event: Listener.Event) {
        if case .partial(let text) = event, paused || talking {
            if paused {
                guard Self.says(Self.continueWords, in: text) else { return }
                paused = false
                speech?.resume()
                listener?.discard()
                show(.status("Continuing"), for: 2)
            } else if Self.says(Self.pauseWords, in: text) {
                paused = true
                speech?.pause()
                listener?.discard()
                show(.status("Paused: say continue"), for: nil)
            } else if Self.says(Self.stopWords, in: text) {
                // While it speaks, only these get through: the rest may be its own echo.
                interrupt()
                listener?.discard()
                show(.status("Listening"), for: 3)
            }
            return
        }
        switch event {
        case .speaking:
            if !talking, !paused { show(.you("..."), for: nil) }
        case .partial(let text):
            if Self.says(Self.pauseWords, in: text) {
                paused = true
                listener?.discard()
                show(.status("Paused: say continue"), for: nil)
                return
            }
            show(.you(text + " ..."), for: nil)
        case .heard(let text):
            guard !talking, !paused else { return }
            show(.you(text), for: Self.subtitleSeconds)
            answer(text)
        default: break
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
