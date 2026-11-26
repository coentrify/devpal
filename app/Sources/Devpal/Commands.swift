import Foundation

/// Known commands, matched in code before the model, so they act the same
/// every time and never report something done that was not.
struct Commands {
    static let remembered = "Noted."
    static let alreadyRemembered = "Already noted."
    static let forgotten = "Forgotten."
    static let nothingToForget = "I had nothing on that."

    private static let lead = #"^(?:[^,]*,\s*)?(?:please\s+|can you\s+|could you\s+|will you\s+)?"#
    private static let remember = try! NSRegularExpression(
        pattern: lead + #"(?:remember|learn|note|don'?t forget|do not forget)(?:\s+that)?[:,]?\s+(.+?)[.!]?$"#, options: [.caseInsensitive])
    private static let forget = try! NSRegularExpression(
        pattern: lead + #"forget(?:\s+(?:that|about))?[:,]?\s+(.+?)[.!]?$"#, options: [.caseInsensitive])
    private static let questionWords: Set<String> = ["what", "when", "who", "where", "why", "how", "if", "whether", "which"]

    let memory: Memory

    /// The spoken answer when what was said is a known command, done first.
    func run(_ text: String) -> String? {
        let said = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !said.hasSuffix("?") else { return nil }
        if let fact = Self.capture(Self.remember, in: said), !Self.isQuestion(fact) {
            let result = memory.remember(Self.sentence(fact))
            return result == "Already remembered." ? Self.alreadyRemembered : Self.remembered
        }
        if let fact = Self.capture(Self.forget, in: said) {
            return memory.forget(fact).hasPrefix("Forgot") ? Self.forgotten : Self.nothingToForget
        }
        return nil
    }

    private static func capture(_ pattern: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = pattern.firstMatch(in: text, range: range), let found = Range(match.range(at: 1), in: text) else { return nil }
        let fact = String(text[found]).trimmingCharacters(in: .whitespaces)
        return fact.isEmpty ? nil : fact
    }

    /// "Remember when..." asks about the past: it is no fact to keep.
    private static func isQuestion(_ fact: String) -> Bool {
        questionWords.contains(fact.lowercased().split(separator: " ").first.map(String.init) ?? "")
    }

    private static func sentence(_ fact: String) -> String {
        let capitalized = fact.prefix(1).uppercased() + fact.dropFirst()
        return ".!?".contains(capitalized.last ?? " ") ? capitalized : capitalized + "."
    }
}
