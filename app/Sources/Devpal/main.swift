import AppKit

let options: Options
do {
    options = try Options.parse(Array(CommandLine.arguments.dropFirst()))
} catch {
    FileHandle.standardError.write(Data("devpal: \(error)\n\(Options.usage)\n".utf8))
    exit(2)
}

if let text = options.say {
    do {
        let speech = Speech(voice: try Persona(folder: options.layers.persona).voice)
        try await speech.load()
        let samples = try await speech.synthesize(text)
        if let file = options.to { try speech.write(samples, to: file) } else { try await speech.play(samples) }
    } catch {
        fail(error)
    }
    exit(0)
}

if let text = options.ask {
    let brain = Brain(tone: (try? Persona(folder: options.layers.persona).tone) ?? "")
    do {
        try await brain.start()
        for try await piece in brain.reply(to: text) { print(piece, terminator: "") }
        print()
        brain.stop()
    } catch {
        brain.stop()
        fail(error)
    }
    exit(0)
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
