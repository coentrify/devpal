import Foundation

/// The command line: which layers to show, and whether to open a window
/// or render one frame to a PNG file.
struct Options {
    var root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    var background = "synthwave"
    var persona = "plain"
    var filter = "crt"
    var snapshot: URL?
    var width = 1280
    var height = 800
    var time: Float = 1.0
    var fullScreen = false
    var listen = true
    var subtitle = ""
    var hear: URL?

    static let usage = """
    Usage: devpal [--background <name>] [--persona <name>] [--filter <name>]
                  [--root <path>] [--full-screen] [--no-listen] [--subtitle <text>] [--hear <file.wav>]
                  [--snapshot <file.png> [--size <width>x<height>] [--time <seconds>]]
    """

    static func parse(_ arguments: [String]) throws -> Options {
        var options = Options()
        var rest = arguments[...]
        func value(_ flag: String) throws -> String {
            guard let next = rest.popFirst() else { throw OptionsError.missingValue(flag) }
            return next
        }
        while let flag = rest.popFirst() {
            switch flag {
            case "--root": options.root = URL(fileURLWithPath: try value(flag))
            case "--background": options.background = try value(flag)
            case "--persona": options.persona = try value(flag)
            case "--filter": options.filter = try value(flag)
            case "--snapshot": options.snapshot = URL(fileURLWithPath: try value(flag))
            case "--full-screen": options.fullScreen = true
            case "--no-listen": options.listen = false
            case "--subtitle": options.subtitle = try value(flag)
            case "--hear": options.hear = URL(fileURLWithPath: try value(flag))
            case "--time":
                guard let time = Float(try value(flag)) else { throw OptionsError.badValue(flag) }
                options.time = time
            case "--size":
                let parts = try value(flag).split(separator: "x").compactMap { Int($0) }
                guard parts.count == 2, parts.allSatisfy({ $0 > 0 }) else { throw OptionsError.badValue(flag) }
                options.width = parts[0]
                options.height = parts[1]
            default: throw OptionsError.unknown(flag)
            }
        }
        return options
    }

    var layers: Layers { Layers(root: root, background: background, persona: persona, filter: filter) }
}

enum OptionsError: Error, CustomStringConvertible {
    case missingValue(String), badValue(String), unknown(String)

    var description: String {
        switch self {
        case .missingValue(let flag): "\(flag) needs a value"
        case .badValue(let flag): "\(flag) has a value it cannot read"
        case .unknown(let flag): "unknown option \(flag)"
        }
    }
}
