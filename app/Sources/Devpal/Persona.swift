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

    init(folder: URL) throws {
        tone = try String(contentsOf: folder.appendingPathComponent("tone.md"), encoding: .utf8)
        voice = try JSONDecoder().decode(Voice.self, from: Data(contentsOf: folder.appendingPathComponent("voice.json")))
        guard voice.engine == "kokoro" else { throw PersonaError.unknownEngine(voice.engine) }
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
