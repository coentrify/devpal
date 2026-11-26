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
    static let maxTokens = 120

    private let model: URL
    private let tone: String
    private var server: Process?
    private let lock = NSLock()
    private var history: [[String: Any]] = []
    private let memory: Memory
    private let machine: Machine?
    private var base: URL { URL(string: "http://127.0.0.1:\(Self.port)")! }

    init(tone: String, memory: Memory = Memory(), machine: Machine? = nil, model: URL = Brain.defaultModel) {
        self.tone = tone
        self.memory = memory
        self.machine = machine
        self.model = model
    }

    func start() async throws {
        guard FileManager.default.fileExists(atPath: model.path) else { throw BrainError.noModel(model.path) }
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
                    var messages = turn.list
                    for round in 0..<Self.toolRounds {
                        // Tools are offered once: after them, the model only answers.
                        let step = try await self.stream(messages, tools: round == 0) { piece in
                            said += piece
                            continuation.yield(piece)
                        }
                        guard !step.calls.isEmpty else { break }
                        // Looking something up takes a while, so it says so first.
                        if step.text.isEmpty, step.calls.contains(where: { $0.name == "ask_machine" }) {
                            said += Self.checking + " "
                            continuation.yield(Self.checking + " ")
                        }
                        messages.append(["role": "assistant", "content": step.text, "tool_calls": step.calls.map(\.json)])
                        for call in step.calls {
                            messages.append(["role": "tool", "tool_call_id": call.id, "content": await self.run(call)])
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
        return (text, calls.keys.sorted().compactMap { calls[$0] })
    }

    private func run(_ call: Call) async -> String {
        let arguments = (try? JSONSerialization.jsonObject(with: Data(call.arguments.utf8))) as? [String: Any]
        switch call.name {
        case "ask_machine":
            guard let machine else { return "Looking things up is off." }
            return await machine.ask(arguments?["question"] as? String ?? "")
        case "remember": return memory.remember(arguments?["fact"] as? String ?? "")
        case "forget": return memory.forget(arguments?["fact"] as? String ?? "")
        default: return "No such tool."
        }
    }

    /// The persona's tone, then what it remembers and how to keep its memory.
    private func instructions() -> String {
        let facts = memory.facts
        let remembered = facts.isEmpty ? "You remember nothing yet." : "What you remember:\n" + facts.map { "- \($0)" }.joined(separator: "\n")
        return [tone, Self.capabilities, Self.memoryRules, remembered].joined(separator: "\n\n")
    }

    /// What it can and cannot do, so it can say so. Kept beside the tools, so it stays true as they change.
    static let capabilities = """
        What you can do: you live on the developer's screen and listen through the microphone. You hear the \
        words they say, and answer out loud, with your words shown as subtitles. You run entirely on their \
        machine: your brain is a small language model, Qwen3 4B, your voice is Kokoro, and your hearing is \
        Parakeet. You keep a memory on this machine, and you remember the last few exchanges of this \
        conversation. You stop talking when the developer starts. To learn anything about the projects on this \
        machine, their files, docs, wikis or progress, call ask_machine: Claude Code looks it up for you, \
        read-only, which takes a little while. What you cannot do yet: change anything in the projects, talk to \
        the agents working on them, or browse the web.
        """

    /// Said while Claude Code looks something up.
    static let checking = "Checking."


    static let memoryRules = """
        You have a memory on this machine. When the developer tells you something worth keeping, or asks you to \
        remember or learn something, call remember with one short fact. When they ask you to forget something, \
        call forget with that fact, copied from what you remember. Only the tools keep or drop a fact: never \
        say you remembered or forgot something without calling the tool. Then confirm in a few words. Answer from what you remember \
        when it helps.
        """

    static let toolRounds = 2
    /// Lower while tools are on offer, so a request to remember is acted on, not only answered.
    static let toolTemperature = 0.3

    static var tools: [[String: Any]] { [
        ["type": "function", "function": [
            "name": "ask_machine",
            "description": "Ask Claude Code about the projects on this machine: their files, docs, wikis and progress.",
            "parameters": ["type": "object", "properties": [
                "question": ["type": "string", "description": "The question, complete and self-contained."],
            ], "required": ["question"]],
        ]],
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
