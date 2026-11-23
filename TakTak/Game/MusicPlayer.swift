import AVFoundation

/// Hafif, ritmik atölye müziği (Audio/workshop_loop.wav, 19,2 sn kesintisiz döngü).
/// Kullanıcı başka bir uygulamada müzik dinliyorsa çalmaz.
final class MusicPlayer {
    static let shared = MusicPlayer()

    var enabled = true {
        didSet { enabled ? play() : stop() }
    }

    private var player: AVAudioPlayer?
    private let volume: Float = 0.32

    private init() {
        if let url = Bundle.main.url(forResource: "workshop_loop", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = volume
            player?.prepareToPlay()
        }
    }

    func play() {
        guard enabled, let player, !player.isPlaying else { return }
        // Oyuncunun kendi müziğinin üstüne çalma
        if AVAudioSession.sharedInstance().isOtherAudioPlaying { return }
        player.volume = 0
        player.play()
        player.setVolume(volume, fadeDuration: 1.2)
    }

    func stop() {
        player?.stop()
    }

    /// Reklam gibi tam ekran içerikler sırasında kısar
    func duck(_ on: Bool) {
        player?.setVolume(on ? 0 : volume, fadeDuration: 0.3)
    }
}
