import Foundation

/// The three layers on the screen, each picked on its own from its folder
/// in the project: a background, a persona and a filter.
struct Layers {
    var background: URL
    var persona: URL
    var filter: URL

    var backgroundShader: URL { background.appendingPathComponent("background.metal") }
    var personaIdleStill: URL { persona.appendingPathComponent("image/idle.svg") }
    var filterShader: URL { filter.appendingPathComponent("filter.metal") }

    init(root: URL, background: String, persona: String, filter: String) {
        self.background = root.appendingPathComponent("backgrounds/\(background)")
        self.persona = root.appendingPathComponent("personas/\(persona)")
        self.filter = root.appendingPathComponent("filters/\(filter)")
    }

    /// Names the first file a layer is missing, so a wrong name fails at once.
    func missingFile() -> URL? {
        [backgroundShader, personaIdleStill, filterShader].first { !FileManager.default.fileExists(atPath: $0.path) }
    }
}
