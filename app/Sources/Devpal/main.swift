import AppKit

let options: Options
do {
    options = try Options.parse(Array(CommandLine.arguments.dropFirst()))
} catch {
    FileHandle.standardError.write(Data("devpal: \(error)\n\(Options.usage)\n".utf8))
    exit(2)
}

if let file = options.hear {
    do {
        for line in try await Listener.hear(file: file) { print(line) }
    } catch {
        fail(error)
    }
    exit(0)
}

if let file = options.snapshot {
    do {
        try Snapshot.write(options, to: file)
        print("devpal: wrote \(file.path)")
    } catch {
        fail(error)
    }
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = Window(options: options)
app.delegate = delegate
app.run()
