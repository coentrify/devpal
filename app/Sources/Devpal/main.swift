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

if !options.classify.isEmpty {
    let brain = Brain(tone: "", memory: Memory(file: options.memory))
    do {
        for text in options.classify { print(try await brain.classify(text).rawValue) }
        brain.stop()
    } catch {
        brain.stop()
        fail(error)
    }
    exit(0)
}

if !options.ask.isEmpty {
    // Each --ask is one turn of the same conversation: one answer per line, then what is announced after.
    let persona: Persona
    do {
        persona = try Persona(folder: options.layers.persona)
    } catch {
        fail(error)
    }
    let memory = Memory(file: options.memory)
    let agents = Agents(projects: options.projects)
    let brain = Brain(tone: persona.tone, memory: memory, agents: agents)
    let conversation = Conversation(persona: persona, memory: memory, brain: brain, agents: agents)
    conversation.onAnnounce = { print($0) }
    do {
        for text in options.ask {
            var line = ""
            let reply = conversation.reply(to: text)
            for try await piece in reply {
                line += piece
            }
            print(line.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        await conversation.finishWork()
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
