import Foundation

/// What the companion has learned, kept on the machine in a plain file, one
/// fact per line, so you can read and edit it yourself.
final class Memory: @unchecked Sendable {
    static let defaultFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".devpal/memory.md")
    static let header = "# Memory\n\nWhat devpal has learned on this machine, one fact per line.\n\n"

    let file: URL
    private let lock = NSLock()

    init(file: URL = Memory.defaultFile) {
        self.file = file
    }

    var facts: [String] {
        lock.withLock { read() }
    }

    func remember(_ fact: String) -> String {
        let fact = fact.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        guard !fact.isEmpty else { return "Nothing to remember." }
        return lock.withLock {
            var facts = read()
            guard !facts.contains(where: { $0.caseInsensitiveCompare(fact) == .orderedSame }) else { return "Already remembered." }
            facts.append(fact)
            return write(facts) ? "Remembered." : "Could not write the memory."
        }
    }

    /// Forgets a fact: the one given, or else the one that shares the most words with it.
    func forget(_ fact: String) -> String {
        let wanted = Self.words(fact)
        guard !wanted.isEmpty else { return "Nothing to forget." }
        return lock.withLock {
            let facts = read()
            let overlap = facts.map { Self.words($0).intersection(wanted).count }
            guard let best = overlap.max(), best > 0 else { return "No fact matched." }
            let exact = facts.firstIndex { $0.caseInsensitiveCompare(fact.trimmingCharacters(in: .whitespaces)) == .orderedSame }
            let gone = exact ?? overlap.firstIndex(of: best)!
            var kept = facts
            let forgotten = kept.remove(at: gone)
            return write(kept) ? "Forgot: \(forgotten)" : "Could not write the memory."
        }
    }

    /// The words of a fact that carry meaning: three letters or more.
    private static func words(_ text: String) -> Set<String> {
        Set(text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count >= 3 })
    }

    private func read() -> [String] {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { return [] }
        return text.split(whereSeparator: \.isNewline)
            .filter { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
    }

    private func write(_ facts: [String]) -> Bool {
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try (Self.header + facts.map { "- \($0)\n" }.joined()).write(to: file, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
}
