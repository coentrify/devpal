import Foundation

/// The small talk model, run on the machine by llama.cpp's server, with the
/// persona's tone as its instructions. It keeps the conversation so far.
final class Brain: @unchecked Sendable {
    static let port = 5276
    static let defaultModel = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".devpal/models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf")
    static let log = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".devpal/logs/brain.log")
    /// The turns kept in the conversation, the oldest dropped first.
    static let turnsKept = 20
    static let startTimeout: TimeInterval = 180

    private let model: URL
    private let tone: String
    private var server: Process?
    private let lock = NSLock()
    private var history: [[String: String]] = []
    private var base: URL { URL(string: "http://127.0.0.1:\(Self.port)")! }

    init(tone: String, model: URL = Brain.defaultModel) {
        self.tone = tone
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

    /// The reply to what was said, as it is written, piece by piece.
    func reply(to text: String) -> AsyncThrowingStream<String, Error> {
        let messages = lock.withLock { () -> [[String: String]] in
            history.append(["role": "user", "content": text])
            history = Array(history.suffix(Self.turnsKept))
            return [["role": "system", "content": tone]] + history
        }
        return AsyncThrowingStream { continuation in
            let task = Task {
                var said = ""
                do {
                    var request = URLRequest(url: base.appendingPathComponent("v1/chat/completions"))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: [
                        "messages": messages, "stream": true, "temperature": 0.7, "max_tokens": 200,
                    ])
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                        let chunk = try JSONSerialization.jsonObject(with: Data(line.dropFirst(6).utf8)) as? [String: Any]
                        let choice = (chunk?["choices"] as? [[String: Any]])?.first
                        if let piece = (choice?["delta"] as? [String: Any])?["content"] as? String, !piece.isEmpty {
                            said += piece
                            continuation.yield(piece)
                        }
                    }
                    lock.withLock { history.append(["role": "assistant", "content": said]) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
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
