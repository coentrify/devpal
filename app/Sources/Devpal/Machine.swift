import Foundation

/// Hands a question on to Claude Code, which looks it up in the projects on
/// the machine, read-only, on the user's own Claude login.
final class Machine: @unchecked Sendable {
    static let timeout: TimeInterval = 180
    static let readOnlyTools = ["Read", "Grep", "Glob", "Bash(ls:*)", "Bash(git log:*)", "Bash(git status:*)"]
    static let instructions = """
        You answer questions for devpal, a voice companion on this machine. The current folder holds the \
        developer's projects, one folder each, with their docs, often in docs/ and served as a VitePress wiki. \
        Look up what the question needs, read-only. Reply in at most three short sentences of plain spoken \
        English, with no markdown, no lists and no file paths unless asked.
        """

    let projects: URL

    init(projects: URL) {
        self.projects = projects
    }

    func ask(_ question: String) async -> String {
        guard let claude = Self.findClaude() else { return "Claude Code is not installed on this machine." }
        let process = Process()
        process.executableURL = claude
        process.currentDirectoryURL = projects
        process.arguments = ["-p", question, "--output-format", "text", "--append-system-prompt", Self.instructions,
                             "--allowedTools"] + Self.readOnlyTools
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return "Claude Code did not start: \(error)"
        }
        let timer = Task {
            try await Task.sleep(for: .seconds(Self.timeout))
            process.terminate()
        }
        let text = await withTaskCancellationHandler {
            await Task.detached { String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self) }.value
        } onCancel: {
            process.terminate()
        }
        timer.cancel()
        process.waitUntilExit()
        let answer = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if process.terminationStatus != 0 || answer.isEmpty { return "Claude Code found no answer." }
        return answer
    }

    /// Claude Code on the PATH, or else the newest one the Claude desktop app keeps.
    static func findClaude() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
            + [home.appendingPathComponent(".local/bin").path, home.appendingPathComponent(".claude/local").path, "/opt/homebrew/bin", "/usr/local/bin"]
        if let found = paths.map({ URL(fileURLWithPath: $0).appendingPathComponent("claude") })
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) {
            return found
        }
        let desktop = home.appendingPathComponent("Library/Application Support/Claude/claude-code")
        let versions = ((try? FileManager.default.contentsOfDirectory(atPath: desktop.path)) ?? [])
            .sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        for version in versions {
            let builds = (try? FileManager.default.contentsOfDirectory(atPath: desktop.appendingPathComponent(version).path)) ?? []
            for build in builds {
                let binary = desktop.appendingPathComponent("\(version)/\(build)/claude.app/Contents/MacOS/claude")
                if FileManager.default.isExecutableFile(atPath: binary.path) { return binary }
            }
        }
        return nil
    }
}
