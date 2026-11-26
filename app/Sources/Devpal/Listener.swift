@preconcurrency import AVFoundation
import FluidAudio
import Foundation

/// Listens on the microphone. A voice detector cuts what you say into
/// sentences at a silence, and each sentence is transcribed on the machine
/// with Parakeet, rescored against the special words.
final class Listener: @unchecked Sendable {
    enum Event: Sendable {
        case ready
        case speaking
        case heard(String)
        case failed(String)
    }

    static let sampleRate = Double(VadManager.sampleRate)
    /// A sentence ends after this much silence.
    static let silence: TimeInterval = 0.75
    /// Audio kept from just before the voice detector fires, so a first word is never clipped.
    static let preRoll: TimeInterval = 0.4

    private let engine = AVAudioEngine()
    private let chunks: AsyncStream<[Float]>
    private let feed: AsyncStream<[Float]>.Continuation
    private let onEvent: @Sendable (Event) -> Void
    private var worker: Task<Void, Never>?

    init(onEvent: @escaping @Sendable (Event) -> Void) {
        (chunks, feed) = AsyncStream.makeStream(of: [Float].self)
        self.onEvent = onEvent
    }

    func start() {
        worker = Task.detached { [chunks, onEvent] in
            do {
                let pipeline = try await Pipeline.load()
                onEvent(.ready)
                try await pipeline.run(chunks, onEvent: onEvent)
            } catch {
                onEvent(.failed("\(error)"))
            }
        }
        do {
            try startMicrophone()
        } catch {
            onEvent(.failed("microphone: \(error)"))
        }
    }

    /// Runs a 16 kHz mono WAV file through the same sentence cutting and
    /// transcription as the microphone, followed by two seconds of silence.
    static func hear(file: URL) async throws -> [String] {
        let pipeline = try await Pipeline.load()
        let samples = try AudioConverter().resampleAudioFile(file) + [Float](repeating: 0, count: Int(2 * sampleRate))
        let (chunks, feed) = AsyncStream.makeStream(of: [Float].self)
        for start in stride(from: 0, to: samples.count, by: 1600) {
            feed.yield(Array(samples[start..<min(start + 1600, samples.count)]))
        }
        feed.finish()
        let heard = Heard()
        try await pipeline.run(chunks) { event in
            if case .heard(let text) = event { heard.append(text) }
        }
        return heard.lines
    }

    func stop() {
        engine.stop()
        feed.finish()
        worker?.cancel()
    }

    private func startMicrophone() throws {
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Self.sampleRate, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: inputFormat, to: target) else {
            throw ListenerError.noAudioFormat
        }
        let feed = self.feed
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * Self.sampleRate / inputFormat.sampleRate) + 32
            guard let converted = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return }
            var consumed = false
            converter.convert(to: converted, error: nil) { _, status in
                if consumed {
                    status.pointee = .noDataNow
                    return nil
                }
                consumed = true
                status.pointee = .haveData
                return buffer
            }
            guard let channel = converted.floatChannelData?[0], converted.frameLength > 0 else { return }
            feed.yield(Array(UnsafeBufferPointer(start: channel, count: Int(converted.frameLength))))
        }
        engine.prepare()
        try engine.start()
    }
}

/// The models and the sentence cutting, run off the main thread.
private struct Pipeline {
    let vad: VadManager
    let asr: AsrManager
    let boosting: VocabularyBoostingSession?

    static func load() async throws -> Pipeline {
        let vad = try await VadManager()
        let asr = AsrManager(config: .default)
        try await asr.loadModels(try await AsrModels.downloadAndLoad(version: .v3))
        let words = Vocabulary.words()
        let boosting = try await VocabularyBoostingSession(
            vocabulary: CustomVocabularyContext(terms: words.map { CustomVocabularyTerm(text: $0) }),
            ctcModels: try await CtcModels.downloadAndLoad()
        )
        return Pipeline(vad: vad, asr: asr, boosting: boosting)
    }

    func run(_ chunks: AsyncStream<[Float]>, onEvent: @Sendable (Listener.Event) -> Void) async throws {
        let config = VadSegmentationConfig(minSilenceDuration: Listener.silence)
        let preRollSamples = Int(Listener.preRoll * Listener.sampleRate)
        var state = await vad.makeStreamState()
        var pending: [Float] = []
        var recent: [Float] = []
        var sentence: [Float]?

        for await samples in chunks {
            pending += samples
            while pending.count >= VadManager.chunkSize {
                let chunk = Array(pending.prefix(VadManager.chunkSize))
                pending.removeFirst(VadManager.chunkSize)
                let result = try await vad.processStreamingChunk(chunk, state: state, config: config)
                state = result.state

                if sentence != nil {
                    sentence! += chunk
                } else {
                    recent = Array((recent + chunk).suffix(preRollSamples + VadManager.chunkSize))
                }
                if result.event?.isStart == true, sentence == nil {
                    sentence = recent
                    onEvent(.speaking)
                }
                if result.event?.isEnd == true, let audio = sentence {
                    sentence = nil
                    recent = []
                    let text = try await transcribe(audio)
                    if !text.isEmpty { onEvent(.heard(text)) }
                }
            }
        }
        // The input ended while someone was still talking: what was said still counts.
        if let audio = sentence {
            let text = try await transcribe(audio + pending)
            if !text.isEmpty { onEvent(.heard(text)) }
        }
    }

    private func transcribe(_ audio: [Float]) async throws -> String {
        var decoder = try TdtDecoderState(decoderLayers: 2)
        let result = try await asr.transcribe(audio, decoderState: &decoder)
        if let boosting, let rescored = await boosting.rescore(text: result.text, tokenTimings: result.tokenTimings ?? [], audioSamples: audio) {
            return rescored.text.trimmingCharacters(in: .whitespaces)
        }
        return result.text.trimmingCharacters(in: .whitespaces)
    }
}

private final class Heard: @unchecked Sendable {
    private let lock = NSLock()
    private var collected: [String] = []
    var lines: [String] { lock.withLock { collected } }
    func append(_ line: String) { lock.withLock { collected.append(line) } }
}

enum ListenerError: Error {
    case noAudioFormat
}
