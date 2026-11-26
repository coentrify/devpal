import Foundation

/// The agents of the projects on the machine: Claude Code, run headless on
/// the user's own Claude login. Each project has one session, resumed every
/// time, so its agent keeps its context and the user can open it too.
final class Agents: @unchecked Sendable {
    enum Rights {
        /// Reads the files, docs and wikis, and changes nothing.
        case read
        /// Edits files and runs git and npm, but never pushes or deletes.
        case work
    }

    static let timeout: TimeInterval = 30 * 60
    static let sessionsFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".devpal/sessions.json")
    static let readTools = ["Read", "Grep", "Glob", "WebFetch", "Bash(ls:*)", "Bash(git log:*)", "Bash(git status:*)", "Bash(git diff:*)"]
    static let workTools = readTools + ["Edit", "Write", "MultiEdit", "Bash(git add:*)", "Bash(git commit:*)", "Bash(git checkout:*)",
                                        "Bash(git switch:*)", "Bash(git branch:*)", "Bash(git stash:*)", "Bash(npm:*)", "Bash(node:*)", "Bash(mkdir:*)"]
    static let neverTools = ["Bash(git push:*)", "Bash(rm:*)", "Bash(git reset:*)", "Bash(git clean:*)"]
    static let speaking = """
        You answer a voice companion, which speaks your reply aloud. Reply in at most two short sentences of plain \
        spoken English, with no markdown, no lists and no file paths unless asked.
        """
    static let working = """
        You work on this project on the developer's orders, given by voice. Never push and never delete files: say \
        so when the order needs it. When you are done, report what you did in at most two short spoken sentences.
        """

    let projects: URL
    private let lock = NSLock()
    private var atWork: [String: Date] = [:]

    init(projects: URL) {
        self.projects = projects
    }

    /// The project folders on the machine.
    var names: [String] {
        ((try? FileManager.default.contentsOfDirectory(at: projects, includingPropertiesForKeys: [.isDirectoryKey])) ?? [])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true && !$0.lastPathComponent.hasPrefix(".") }
            .map(\.lastPathComponent).sorted()
    }

    /// The project folder a spoken name points at, such as "johnny cyberquest" for johnny-cyberquest.
    func project(named spoken: String) -> String? {
        let wanted = Self.squash(spoken)
        return names.first { Self.squash($0) == wanted }
    }

    /// Since when a project's agent has been at work, if it is.
    func busySince(_ project: String) -> Date? {
        lock.withLock { atWork[project] }
    }

    /// Asks a project's agent, or Claude Code across all projects when there is none, and returns its reply.
    func ask(_ message: String, project: String?, rights: Rights) async -> String {
        guard let claude = Self.findClaude() else { return "Claude Code is not installed on this machine." }
        if let project, busySince(project) != nil, rights == .read {
            return "The \(project) agent is still at work on an order."
        }
        let folder = project.map { projects.appendingPathComponent($0) } ?? projects
        let session = project == nil ? nil : sessions[folder.path]
        var arguments = ["-p", message, "--output-format", "json",
                         "--append-system-prompt", rights == .work ? Self.working : Self.speaking,
                         "--disallowedTools"] + Self.neverTools
        arguments += ["--allowedTools"] + (rights == .work ? Self.workTools : Self.readTools)
        if rights == .work { arguments += ["--permission-mode", "acceptEdits"] }
        if let session { arguments += ["--resume", session] }

        if let project { lock.withLock { atWork[project] = rights == .work ? Date() : atWork[project] } }
        defer { if let project, rights == .work { _ = lock.withLock { atWork.removeValue(forKey: project) } } }
        let output = await Self.run(claude, arguments, in: folder)

        guard let data = output.data(using: .utf8), let reply = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return output.contains("Not logged in") ? "Claude Code is not signed in on this machine." : "The agent gave no answer."
        }
        if project != nil, let id = reply["session_id"] as? String { remember(session: id, for: folder.path) }
        let text = (reply["result"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if reply["is_error"] as? Bool == true { return text.isEmpty ? "The agent ran into an error." : text }
        return text.isEmpty ? "The agent gave no answer." : text
    }

    /// Clones a repository by its spoken name over SSH, from the GitHub owners the machine's projects already use.
    func clone(_ spoken: String) async -> (project: String?, message: String) {
        if let existing = project(named: spoken) { return (existing, "\(existing) is already on this machine.") }
        let owners = await self.owners()
        for owner in owners {
            for name in Self.repoNames(spoken) {
                let url = "git@github.com:\(owner)/\(name).git"
                guard await Self.run(URL(fileURLWithPath: "/usr/bin/git"), ["ls-remote", "--heads", url], in: projects, status: true) == "0" else { continue }
                let target = projects.appendingPathComponent(name).path
                let cloned = await Self.run(URL(fileURLWithPath: "/usr/bin/git"), ["clone", "--quiet", url, target], in: projects, status: true)
                return cloned == "0" ? (name, "Cloned \(owner)/\(name).") : (nil, "Cloning \(owner)/\(name) failed.")
            }
        }
        return (nil, "No repository named \(spoken) under \(owners.joined(separator: " or ")).")
    }

    /// The GitHub owners of the projects already on the machine.
    private func owners() async -> [String] {
        var found: [String] = []
        for name in names {
            let url = await Self.run(URL(fileURLWithPath: "/usr/bin/git"), ["-C", projects.appendingPathComponent(name).path, "remote", "get-url", "origin"], in: projects)
            if let owner = url.split(separator: ":").last?.split(separator: "/").first.map(String.init),
               url.contains("github.com"), !found.contains(owner) {
                found.append(owner)
            }
        }
        return found
    }

    private var sessions: [String: String] {
        lock.withLock {
            guard let data = try? Data(contentsOf: Self.sessionsFile) else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
    }

    /// Sessions are kept by project folder, so two folders with the same name never share one.
    private func remember(session: String, for folder: String) {
        lock.withLock {
            var all = (try? JSONDecoder().decode([String: String].self, from: Data(contentsOf: Self.sessionsFile))) ?? [:]
            all[folder] = session
            try? FileManager.default.createDirectory(at: Self.sessionsFile.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? JSONEncoder().encode(all).write(to: Self.sessionsFile)
        }
    }

    static func squash(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// The ways a spoken name is written as a repository: johnny-cyberquest, johnnycyberquest, johnny_cyberquest.
    static func repoNames(_ spoken: String) -> [String] {
        let words = spoken.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        var names = [words.joined(separator: "-"), words.joined(), words.joined(separator: "_")]
        names = names.filter { !$0.isEmpty }
        return names.reduce(into: []) { if !$0.contains($1) { $0.append($1) } }
    }

    /// Runs a command and returns its output, or its exit status when asked.
    private static func run(_ executable: URL, _ arguments: [String], in folder: URL, status: Bool = false) async -> String {
        await withCheckedContinuation { done in
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments
            process.currentDirectoryURL = folder
            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { finished in
                let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                done.resume(returning: status ? "\(finished.terminationStatus)" : text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            do {
                try process.run()
            } catch {
                done.resume(returning: status ? "-1" : "")
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + Self.timeout) { if process.isRunning { process.terminate() } }
        }
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
