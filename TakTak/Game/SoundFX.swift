import AVFoundation

/// Ses efektleri kod ile sentezlenir; ses dosyası gerekmez.
/// İleride gerçek kayıtlarla değiştirmek için `play(_:)` imzası korunabilir.
final class SoundFX {
    static let shared = SoundFX()

    enum Kind: CaseIterable {
        case perfect, good, drive, miss, coin
    }

    var enabled = true

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private let format: AVAudioFormat
    private var buffers: [Kind: AVAudioPCMBuffer] = [:]
    private let sampleRate: Double = 44_100

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

        // .ambient: diğer seslerle karışır ve sessiz modda susar.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])

        for _ in 0..<4 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: format)
            players.append(p)
        }
        engine.mainMixerNode.outputVolume = 0.9

        buildBuffers()
    }

    func play(_ kind: Kind) {
        guard enabled, let buffer = buffers[kind] else { return }
        if !engine.isRunning {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                try engine.start()
            } catch {
                return
            }
        }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    // MARK: - Sentez

    private func buildBuffers() {
        let twoPi = 2 * Double.pi

        // Mükemmel: tok "TAK" (alçak gümbürtü + metalik tık + ilk anda kısa vuruş gürültüsü)
        buffers[.perfect] = makeBuffer(duration: 0.22) { t in
            let thump = sin(twoPi * 105 * t) * exp(-t * 26) * 0.9
            let tock = sin(twoPi * 840 * t) * exp(-t * 42) * 0.45
            let ring = sin(twoPi * 2350 * t) * exp(-t * 60) * 0.12
            let click = t < 0.005 ? Double.random(in: -1...1) * 0.7 : 0
            return Float((thump + tock + ring) * 0.85 + click)
        }

        // İyi: daha ince, kısa "tık"
        buffers[.good] = makeBuffer(duration: 0.12) { t in
            let tick = sin(twoPi * 1250 * t) * exp(-t * 55) * 0.5
            let body = sin(twoPi * 180 * t) * exp(-t * 40) * 0.4
            let click = t < 0.003 ? Double.random(in: -1...1) * 0.5 : 0
            return Float(tick + body + click)
        }

        // İkinci vuruşla oturma: orta ton
        buffers[.drive] = makeBuffer(duration: 0.16) { t in
            let thump = sin(twoPi * 140 * t) * exp(-t * 30) * 0.8
            let tock = sin(twoPi * 700 * t) * exp(-t * 45) * 0.35
            return Float(thump + tock)
        }

        // Eğilme: aşağı kayan, titreşimli "boing"
        buffers[.miss] = makeBuffer(duration: 0.45) { t in
            let f = 320 - 220 * min(t / 0.4, 1)
            let wobble = 1 + 0.08 * sin(twoPi * 18 * t)
            let tone = sin(twoPi * f * wobble * t) * exp(-t * 6) * 0.6
            let grit = Double.random(in: -1...1) * exp(-t * 30) * 0.25
            return Float(tone + grit)
        }

        // Para: iki notalı parlak çın
        buffers[.coin] = makeBuffer(duration: 0.22) { t in
            let f: Double = t < 0.07 ? 1318.5 : 1760
            let local = t < 0.07 ? t : t - 0.07
            return Float(sin(twoPi * f * t) * exp(-local * 18) * 0.35)
        }
    }

    private func makeBuffer(duration: Double, _ sample: (Double) -> Float) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        let fadeOut = Int(0.01 * sampleRate)
        for i in 0..<Int(frames) {
            var v = sample(Double(i) / sampleRate)
            let remaining = Int(frames) - i
            if remaining < fadeOut { v *= Float(remaining) / Float(fadeOut) }
            channel[i] = max(-1, min(1, v))
        }
        return buffer
    }
}
