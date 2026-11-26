import Foundation

/// The thing that talks: its tone, its voice and its image, from its folder.
struct Persona {
    struct Voice: Decodable {
        var engine: String
        var voice: String
        var speed: Float
    }

    let tone: String
    let voice: Voice
    /// Fixed answers to known phrases, said without the model, the same every time.
    let replies: [String: String]

    init(folder: URL) throws {
        tone = try String(contentsOf: folder.appendingPathComponent("tone.md"), encoding: .utf8)
        let repliesFile = folder.appendingPathComponent("replies.json")
        replies = FileManager.default.fileExists(atPath: repliesFile.path)
            ? try JSONDecoder().decode([String: String].self, from: Data(contentsOf: repliesFile)) : [:]
        voice = try JSONDecoder().decode(Voice.self, from: Data(contentsOf: folder.appendingPathComponent("voice.json")))
        guard voice.engine == "kokoro" else { throw PersonaError.unknownEngine(voice.engine) }
    }
}

extension Persona {
    /// The fixed answer when what was said holds one of the known phrases, word for word.
    func fixedReply(to text: String) -> String? {
        let said = Self.words(text)
        return replies.first { phrase, _ in
            let wanted = Self.words(phrase)
            return !wanted.isEmpty && said.indices.contains { Array(said[$0...].prefix(wanted.count)) == wanted }
        }?.value
    }

    static func words(_ text: String) -> [String] {
        text.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
    }
}

enum PersonaError: Error, CustomStringConvertible {
    case unknownEngine(String)

    var description: String {
        switch self {
        case .unknownEngine(let engine): "the voice engine \(engine) is unknown"
        }
    }
}
