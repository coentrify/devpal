import Foundation

/// The special words speech recognition listens for: names, brands and odd
/// verbs. Devpal ships its own name, and each machine adds its own words,
/// one per line, in ~/.devpal/vocabulary.txt, which stays on the machine.
enum Vocabulary {
    static let shipped = ["devpal"]
    static let file = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".devpal/vocabulary.txt")

    static func words() -> [String] {
        let local = (try? String(contentsOf: file, encoding: .utf8))?
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") } ?? []
        var seen = Set<String>()
        return (shipped + local).filter { seen.insert($0.lowercased()).inserted }
    }
}
