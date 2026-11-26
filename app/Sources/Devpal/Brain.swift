import Foundation

/// The small talk model, run on the machine by llama.cpp's server, with the
/// persona's tone and its memory as its instructions. It keeps the
/// conversation so far, and keeps its memory with two tools: remember and forget.
final class Brain: @unchecked Sendable {
    static let port = 5276
    static let defaultModel = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".devpal/models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf")
    static let log = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".devpal/logs/brain.log")
    /// The turns kept in the conversation, the oldest dropped first.
    static let turnsKept = 20
    static let startTimeout: TimeInterval = 180
    /// A spoken answer never runs longer than this, whatever the tone asks.
    static let maxTokens = 60

    private let model: URL
    private let tone: String
    private var server: Process?
    private let lock = NSLock()
    private var history: [[String: Any]] = []
    private let memory: Memory
    private let agents: Agents?
    private var focused: String?

    /// The project in focus: questions and orders go to its agent.
    var focus: String? {
        get { lock.withLock { focused } }
        set { lock.withLock { focused = newValue } }
    }


    private var base: URL { URL(string: "http://127.0.0.1:\(Self.port)")! }

    init(tone: String, memory: Memory = Memory(), agents: Agents? = nil, model: URL = Brain.defaultModel) {
        self.tone = tone
        self.memory = memory
        self.agents = agents
        self.model = model
    }

    /// Starts the model's server, once: later calls return at once while it is up.
    func start() async throws {
        guard FileManager.default.fileExists(atPath: model.path) else { throw BrainError.noModel(model.path) }
        if let server, server.isRunning, await healthy() { return }
        if !(await healthy()) {
            guard let binary = Self.findServer() else { throw BrainError.noServer }
            try FileManager.default.createDirectory(at: Self.log.deletingLastPathComponent(), withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: Self.log.path, contents: nil)
            let process = Process()
            process.executableURL = binary
            process.arguments = ["-m", model.path, "--host", "127.0.0.1", "--port", "\(Self.port)", "-c", "8192", "--jinja"]
            let log = try FileHandle(forWritingTo: Self.log)
            process.standardOutput = log
            process.standardError = log
            try process.run()
            server = process
        }
        let deadline = Date().addingTimeInterval(Self.startTimeout)
        while !(await healthy()) {
            if let server, !server.isRunning { throw BrainError.serverStopped(Self.log.path) }
            if Date() > deadline { throw BrainError.serverStopped(Self.log.path) }
            try await Task.sleep(for: .milliseconds(250))
        }
    }

    func stop() {
        server?.terminate()
    }

    /// The reply to what was said, as it is written, piece by piece. The
    /// model may call a memory tool first, and then answers.
    func reply(to text: String) -> AsyncThrowingStream<String, Error> {
        let turn = lock.withLock { () -> Messages in
            history.append(["role": "user", "content": text])
            history = Array(history.suffix(Self.turnsKept))
            return Messages(list: history)
        }
        return AsyncThrowingStream { continuation in
            let task = Task {
                var said = ""
                do {
                    try await self.start()
                    var messages = turn.list
                    for round in 0..<Self.toolRounds {
                        // Tools are offered once: after them, the model only answers.
                        let step = try await self.stream(messages, tools: round == 0) { piece in
                            said += piece
                            continuation.yield(piece)
                        }
                        guard !step.calls.isEmpty else { break }
                        messages.append(["role": "assistant", "content": step.text, "tool_calls": step.calls.map(\.json)])
                        for call in step.calls {
                            messages.append(["role": "tool", "tool_call_id": call.id, "content": self.run(call)])
                        }
                    }
                    self.lock.withLock { self.history.append(["role": "assistant", "content": said]) }
                    continuation.finish()
                } catch {
                    // An interrupted answer is kept as far as it got.
                    if !said.isEmpty { self.lock.withLock { self.history.append(["role": "assistant", "content": said + " ..."]) } }
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Chat messages are plain JSON, only handed over, never shared while changing.
    private struct Messages: @unchecked Sendable {
        var list: [[String: Any]]
    }

    private struct Call {
        var id = ""
        var name = ""
        var arguments = ""

        var json: [String: Any] {
            ["id": id, "type": "function", "function": ["name": name, "arguments": arguments]]
        }
    }

    /// One request to the model: its text goes out as it comes, its tool calls come back.
    private func stream(_ messages: [[String: Any]], tools: Bool, onText: (String) -> Void) async throws -> (text: String, calls: [Call]) {
        var request = URLRequest(url: base.appendingPathComponent("v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "messages": [["role": "system", "content": instructions()]] + messages,
            "stream": true, "temperature": tools ? Self.toolTemperature : 0.7, "max_tokens": Self.maxTokens,
            "repeat_penalty": Self.repeatPenalty,
        ]
        if tools { body["tools"] = Self.tools }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (bytes, _) = try await URLSession.shared.bytes(for: request)
        var text = ""
        var calls: [Int: Call] = [:]
        for try await line in bytes.lines {
            guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
            let chunk = try JSONSerialization.jsonObject(with: Data(line.dropFirst(6).utf8)) as? [String: Any]
            let delta = ((chunk?["choices"] as? [[String: Any]])?.first?["delta"]) as? [String: Any]
            if let piece = delta?["content"] as? String, !piece.isEmpty {
                text += piece
                onText(piece)
            }
            for part in delta?["tool_calls"] as? [[String: Any]] ?? [] {
                let index = part["index"] as? Int ?? 0
                var call = calls[index] ?? Call()
                if let id = part["id"] as? String { call.id = id }
                let function = part["function"] as? [String: Any]
                if let name = function?["name"] as? String { call.name += name }
                if let arguments = function?["arguments"] as? String { call.arguments += arguments }
                calls[index] = call
            }
        }
        let found = calls.keys.sorted().compactMap { calls[$0] }
        if Self.debug { FileHandle.standardError.write(Data("devpal debug: brain tools=\(tools) text=\(text) calls=\(found.map { "\($0.name)(\($0.arguments))" })\n".utf8)) }
        return (text, found)
    }

    /// With DEVPAL_DEBUG=1, what the model does goes to standard error, and nowhere else.
    private static let debug = ProcessInfo.processInfo.environment["DEVPAL_DEBUG"] == "1"

    private func run(_ call: Call) -> String {
        let arguments = (try? JSONSerialization.jsonObject(with: Data(call.arguments.utf8))) as? [String: Any]
        switch call.name {
        case "remember": return memory.remember(arguments?["fact"] as? String ?? "")
        case "forget": return memory.forget(arguments?["fact"] as? String ?? "")
        default: return "No such tool."
        }
    }

    /// The persona's tone, then what it remembers and how to keep its memory.
    private func instructions() -> String {
        let facts = memory.facts
        let remembered = facts.isEmpty ? "You remember nothing yet." : "What you remember:\n" + facts.map { "- \($0)" }.joined(separator: "\n")
        let focusLine = focus.map { "The project in focus is \($0)." } ?? "No project is in focus."
        let projects = "The projects on this machine: \((agents?.names ?? []).joined(separator: ", "))."
        return [tone, Self.rules, projects, focusLine, remembered].joined(separator: "\n\n")
    }

    /// Hard rules, short and numbered, as a small model follows them best. What it can do is listed from
    /// what is wired up, so it never claims an ability it does not have.
    static let rules = """
        Rules:
        1. Answer in one short sentence, and stop. Never repeat yourself.
        2. You live on the developer's screen. You hear them through the microphone and answer out loud.
        3. You run on their machine: Qwen3 4B is your brain, Kokoro your voice, Parakeet your hearing.
        4. Each project has an agent, Claude Code. Questions about a project go to its agent, and orders start after the developer says go. That is handled for you.
        5. You know nothing about the projects beyond what you remember. Never guess about them.
        6. The developer focuses a project with "work on" and its name, leaves it with "back to base", and clones one with "clone" and its name.
        7. They stop you by saying stop. You keep a memory on this machine: "remember that" and "forget" change it.
        8. You cannot push code, delete files or browse the web.
        9. When you cannot tell what they mean, ask one short question.
        10. Call remember or forget only when the developer asks you to keep or drop a fact.
        """

    /// Said while an agent looks something up.
    static let checking = "Checking."

    static let toolRounds = 2
    /// Lower while tools are on offer, so a request to remember is acted on, not only answered.
    static let toolTemperature = 0.0
    /// Discourages saying the same words again.
    static let repeatPenalty = 1.15

    static var tools: [[String: Any]] { [
        ["type": "function", "function": [
            "name": "remember",
            "description": "Keep a fact in memory for later conversations.",
            "parameters": ["type": "object", "properties": [
                "fact": ["type": "string", "description": "The fact, as one short sentence."],
            ], "required": ["fact"]],
        ]],
        ["type": "function", "function": [
            "name": "forget",
            "description": "Forget one remembered fact.",
            "parameters": ["type": "object", "properties": [
                "fact": ["type": "string", "description": "The remembered fact to forget, copied from what you remember."],
            ], "required": ["fact"]],
        ]],
    ] }

    /// What a sentence asks for, so it is routed in code.
    enum Intent: String, CaseIterable {
        /// A question about the projects: what one is, holds, or how it is going.
        case question
        /// Work to do on a project.
        case order
        /// Anything else: talk, the companion itself, its memory.
        case chat
    }

    static let classifying = """
        Classify what the developer said to their voice companion. Answer with one word.
        question: asks about a software project, its files, docs, wiki, tickets, agents, progress or status.
        order: asks for work on a project: write, change, add, fix, run, build, test, commit, start working.
        chat: anything else, such as greetings, thanks, jokes, questions about the companion, or about the time.
        Examples:
        "What's the status?" question
        "What is Addix about?" question
        "How far along is the city map?" question
        "wat did the agent do last" question
        "Is there a wiki page about the districts?" question
        "Can you tell me about the order of the districts?" question
        "Create a file called notes.txt." order
        "Fix the broken link on the overview page." order
        "Start working on the next ticket." order
        "Add a district called Neon Row." order
        "run the tests" order
        "Commit the changes." order
        "How are you?" chat
        "Tell me a joke." chat
        "What can you do?" chat
        "Who are you?" chat
        "I ordered pizza." chat
        "Thanks." chat
        "Good night." chat
        """

    /// Sorts a sentence into question, order or chat. The model can only answer one of the three.
    func classify(_ text: String) async throws -> Intent {
        try await start()
        var request = URLRequest(url: base.appendingPathComponent("v1/chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let choices = Intent.allCases.map(\.rawValue)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "messages": [["role": "system", "content": Self.classifying], ["role": "user", "content": text]],
            "temperature": 0, "max_tokens": 24,
            "response_format": ["type": "json_schema", "json_schema": ["name": "intent", "schema": [
                "type": "object", "properties": ["intent": ["type": "string", "enum": choices]], "required": ["intent"],
            ]]],
        ] as [String: Any])
        let (data, _) = try await URLSession.shared.data(for: request)
        let reply = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let message = ((reply?["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String ?? ""
        let intent = (try? JSONSerialization.jsonObject(with: Data(message.utf8)) as? [String: Any])?["intent"] as? String
        if Self.debug { FileHandle.standardError.write(Data("devpal debug: \(text) -> \(intent ?? "?")\n".utf8)) }
        return intent.flatMap(Intent.init(rawValue:)) ?? .chat
    }

    /// Keeps an exchange that went elsewhere, such as to an agent, so the conversation still holds it.
    func note(_ said: String, _ answer: String) {
        lock.withLock {
            history.append(["role": "user", "content": said])
            history.append(["role": "assistant", "content": answer])
            history = Array(history.suffix(Self.turnsKept))
        }
    }

    private func healthy() async -> Bool {
        var request = URLRequest(url: base.appendingPathComponent("health"))
        request.timeoutInterval = 1
        guard let (_, response) = try? await URLSession.shared.data(for: request) else { return false }
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private static func findServer() -> URL? {
        let paths = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
        return (paths + ["/opt/homebrew/bin", "/usr/local/bin"])
            .map { URL(fileURLWithPath: $0).appendingPathComponent("llama-server") }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}

enum BrainError: Error, CustomStringConvertible {
    case noModel(String), noServer, serverStopped(String)

    var description: String {
        switch self {
        case .noModel(let path): "no talk model at \(path)"
        case .noServer: "llama-server is not installed (brew install llama.cpp)"
        case .serverStopped(let log): "the talk model did not start, see \(log)"
        }
    }
}

/// Cuts streamed text into sentences, so each is spoken as soon as it is ready.
/// A sentence ends at a . ! or ? followed by a space, so a dot inside a word,
/// such as a version or a domain, does not end one.
struct Sentences {
    private var buffer = ""

    mutating func add(_ piece: String) -> [String] {
        buffer += piece
        var done: [String] = []
        var index = buffer.startIndex
        while index < buffer.endIndex {
            guard ".!?".contains(buffer[index]) else {
                index = buffer.index(after: index)
                continue
            }
            var next = buffer.index(after: index)
            while next < buffer.endIndex, ".!?\"')".contains(buffer[next]) { next = buffer.index(after: next) }
            guard next < buffer.endIndex else { break }
            if buffer[next].isWhitespace {
                let sentence = buffer[..<next].trimmingCharacters(in: .whitespacesAndNewlines)
                buffer = String(buffer[next...])
                index = buffer.startIndex
                if !sentence.isEmpty { done.append(sentence) }
            } else {
                index = next
            }
        }
        return done
    }

    mutating func rest() -> String? {
        let last = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        buffer = ""
        return last.isEmpty ? nil : last
    }
}
