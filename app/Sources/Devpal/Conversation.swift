import Foundation

/// One turn at a time: what you said, and what the companion answers. Known
/// phrases and commands are handled in code, the rest by the brain. Work a
/// project's agent does goes on in the background, and is announced when done.
@MainActor
final class Conversation {
    /// Something that changes the machine, waiting for your go.
    enum Order: Equatable {
        case clone(String)
        case work(project: String, order: String)
    }

    static let underway = "Underway."
    static let cloning = "Cloning."
    static let cancelled = "Cancelled."
    static let backToBase = "Back to base."
    static let introduce = "Read this project's docs and tell me in two short sentences what it is and where it stands."
    static let yes: [[String]] = [["go"], ["yes"], ["yeah"], ["do", "it"], ["proceed"], ["confirm"], ["affirmative"], ["make", "it", "so"], ["execute"]]
    static let no: [[String]] = [["no"], ["cancel"], ["abort"], ["never", "mind"], ["negative"], ["don't"], ["stop"]]

    private static let lead = #"^(?:[^,]*,\s*)?(?:please\s+|can you\s+|could you\s+|will you\s+|let'?s\s+)?"#
    private static let focusPattern = try! NSRegularExpression(
        pattern: lead + #"(?:work on|focus on|switch to|open up|open|go to)\s+(?:the\s+)?(.+?)(?:\s+project)?[.!?]?$"#, options: [.caseInsensitive])
    private static let basePattern = try! NSRegularExpression(
        pattern: #"\b(?:back to base|unfocus|leave (?:the )?project|stop working on)\b"#, options: [.caseInsensitive])
    private static let clonePattern = try! NSRegularExpression(
        pattern: lead + #"clone\s+(?:the\s+)?(.+?)(?:\s+(?:repo|repository))?(?:\s+(?:on|to|onto) this machine|\s+here)?[.!?]?$"#, options: [.caseInsensitive])

    let persona: Persona
    let memory: Memory
    let commands: Commands
    let brain: Brain
    let agents: Agents
    /// Called with what the companion says on its own, such as an agent's report.
    var onAnnounce: (String) -> Void = { _ in }
    /// Called when the project in focus changes.
    var onFocus: (String?) -> Void = { _ in }

    private(set) var focus: String? {
        didSet {
            brain.focus = focus
            onFocus(focus)
        }
    }
    private let waiting = Waiting()
    private var work: [Task<Void, Never>] = []

    init(persona: Persona, memory: Memory, brain: Brain, agents: Agents) {
        self.persona = persona
        self.memory = memory
        self.commands = Commands(memory: memory)
        self.brain = brain
        self.agents = agents
    }

    func reply(to text: String) -> AsyncThrowingStream<String, Error> {
        if let order = waiting.take() {
            if Self.says(Self.yes, in: text) { return Self.just(start(order)) }
            if Self.says(Self.no, in: text) { return Self.just(Self.cancelled) }
        }
        if let fixed = persona.fixedReply(to: text) ?? commands.run(text) ?? projectCommand(text) {
            return Self.just(fixed)
        }
        // The rest is sorted into question, order or chat by the model, and routed here in code.
        return AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    var intent = try await brain.classify(text)
                    // What the memory already answers needs no agent.
                    if intent == .question, memory.answers(text) { intent = .chat }
                    switch intent {
                    case .question:
                        continuation.yield(Brain.checking + " ")
                        let answer = await agents.ask(text, project: focus, rights: .read)
                        brain.note(text, answer)
                        continuation.yield(answer)
                    case .order:
                        guard let project = focus else {
                            continuation.yield(Self.whichProject)
                            break
                        }
                        waiting.set(.work(project: project, order: text))
                        continuation.yield("Order for \(project): \(Self.readBack(text)) Go?")
                    case .chat:
                        for try await piece in brain.reply(to: text) { continuation.yield(piece) }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static let whichProject = "Which project? Say work on, and its name."

    /// An order as it is read back: your own words, as a sentence.
    private static func readBack(_ order: String) -> String {
        let trimmed = order.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentence = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        return ".!?".contains(sentence.last ?? " ") ? sentence : sentence + "."
    }

    /// Waits until every piece of background work is done.
    func finishWork() async {
        for task in work { await task.value }
    }

    private func projectCommand(_ text: String) -> String? {
        let said = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if Self.basePattern.firstMatch(in: said, range: NSRange(said.startIndex..., in: said)) != nil {
            focus = nil
            return Self.backToBase
        }
        if let name = Self.capture(Self.clonePattern, in: said) {
            waiting.set(.clone(name))
            return "Clone \(name) onto this machine. Go?"
        }
        if let name = Self.capture(Self.focusPattern, in: said), let project = agents.project(named: name) {
            focus = project
            return "Focus on \(project)."
        }
        return nil
    }

    private func start(_ order: Order) -> String {
        switch order {
        case .clone(let name):
            background {
                let cloned = await self.agents.clone(name)
                guard let project = cloned.project else { return cloned.message }
                self.focus = project
                let intro = await self.agents.ask(Self.introduce, project: project, rights: .read)
                return "\(cloned.message) \(intro)"
            }
            return Self.cloning
        case .work(let project, let order):
            background { await self.agents.ask(order, project: project, rights: .work) }
            return Self.underway
        }
    }

    private func background(_ job: @escaping @MainActor () async -> String) {
        work.append(Task { @MainActor in
            let report = await job()
            onAnnounce(report)
        })
    }

    private static func says(_ phrases: [[String]], in text: String) -> Bool {
        let heard = Persona.words(text)
        return phrases.contains { phrase in heard.indices.contains { Array(heard[$0...].prefix(phrase.count)) == phrase } }
    }

    private static func capture(_ pattern: NSRegularExpression, in text: String) -> String? {
        guard let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let found = Range(match.range(at: 1), in: text) else { return nil }
        let name = String(text[found]).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    static func just(_ text: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.yield(text); $0.finish() }
    }
}

/// The order waiting for a go, set by the brain from any thread.
private final class Waiting: @unchecked Sendable {
    private let lock = NSLock()
    private var order: Conversation.Order?

    func set(_ order: Conversation.Order) {
        lock.withLock { self.order = order }
    }

    func take() -> Conversation.Order? {
        lock.withLock {
            defer { order = nil }
            return order
        }
    }
}
