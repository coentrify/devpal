@preconcurrency import AVFoundation
import FluidAudio
import Foundation

/// Speaks in the persona's voice: Kokoro on the machine, played through the speaker.
final class Speech: @unchecked Sendable {
    private let kokoro: KokoroAneManager
    private let voice: Persona.Voice
    private let engine: AVAudioEngine
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Double(KokoroAneConstants.sampleRate), channels: 1)!

    init(voice: Persona.Voice, engine: AVAudioEngine = AVAudioEngine()) {
        self.voice = voice
        self.engine = engine
        kokoro = KokoroAneManager(defaultVoice: voice.voice, version: .v3)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func load() async throws {
        try await kokoro.initialize(preloadVoices: [voice.voice])
    }

    /// The samples of one sentence, at 24 kHz.
    func synthesize(_ text: String) async throws -> [Float] {
        try await kokoro.synthesizeDetailed(text: text, voice: voice.voice, speed: voice.speed).samples
    }

    /// Plays samples to the end.
    func play(_ samples: [Float]) async throws {
        guard !samples.isEmpty, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        if !engine.isRunning { try engine.start() }
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in done.resume() }
            if !player.isPlaying { player.play() }
        }
    }

    /// Holds the speech where it is, to go on later.
    func pause() {
        player.pause()
    }

    /// Goes on where the speech was held.
    func resume() {
        player.play()
    }

    /// Stops speaking at once. What was still to play is dropped.
    func stop() {
        player.stop()
    }

    /// Writes samples to a 16-bit WAV file.
    func write(_ samples: [Float], to file: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: format.sampleRate, AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
        ]
        let out = try AVAudioFile(forWriting: file, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        try out.write(from: buffer)
    }
}
