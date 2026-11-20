import CoreHaptics
import UIKit

/// Titreşim geri bildirimleri. Basit oyunu "iyi hissettiren" şeyin yarısı budur.
///
/// Destekleyen cihazlarda Core Haptics ile özel desenler çalınır (keskin "TAK" vuruşu,
/// çivi eğilince üçlü sarsıntı). Desteklemeyenlerde UIFeedbackGenerator'a düşer.
enum Haptics {
    static var enabled = true

    private static let supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private static var engine: CHHapticEngine?
    private static var engineRunning = false

    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let notify = UINotificationFeedbackGenerator()

    /// Oyun ekranı açılırken çağrılır; ilk vuruşta gecikme olmasın diye motoru hazırlar.
    static func prepare() {
        guard enabled else { return }
        if supportsCoreHaptics {
            startEngineIfNeeded()
        } else {
            heavy.prepare()
            medium.prepare()
            notify.prepare()
        }
    }

    /// Mükemmel vuruş: sert, keskin bir darbe ve hemen ardından hafif bir yankı.
    static func perfect() {
        guard enabled else { return }
        if !play([(0, 1.0, 0.9), (0.035, 0.45, 0.3)]) {
            heavy.impactOccurred(intensity: 1.0)
        }
    }

    /// İyi vuruş: orta şiddette.
    static func good() {
        guard enabled else { return }
        if !play([(0, 0.7, 0.6)]) {
            medium.impactOccurred(intensity: 0.8)
        }
    }

    /// Çivi eğildi ya da kaçtı: üç kısa, kalın sarsıntı.
    static func miss() {
        guard enabled else { return }
        if !play([(0, 1.0, 0.2), (0.09, 0.8, 0.15), (0.18, 0.6, 0.1)]) {
            notify.notificationOccurred(.error)
        }
    }

    /// Menü dokunuşları, boş vuruş vb.
    static func tap() {
        guard enabled else { return }
        if !play([(0, 0.45, 0.8)]) {
            light.impactOccurred()
        }
    }

    /// Satın alma, ödül alma.
    static func success() {
        guard enabled else { return }
        if !play([(0, 0.6, 0.9), (0.1, 0.9, 0.9)]) {
            notify.notificationOccurred(.success)
        }
    }

    // MARK: - Core Haptics

    private static func startEngineIfNeeded() {
        guard supportsCoreHaptics else { return }
        if engine == nil {
            do {
                let e = try CHHapticEngine()
                e.playsHapticsOnly = true
                e.isAutoShutdownEnabled = false
                // Uygulama arka plana gidince ya da sistem motoru sıfırlayınca bir sonraki
                // titreşimde yeniden başlatılır.
                e.stoppedHandler = { _ in
                    DispatchQueue.main.async { engineRunning = false }
                }
                e.resetHandler = {
                    DispatchQueue.main.async {
                        engineRunning = false
                        startEngineIfNeeded()
                    }
                }
                engine = e
            } catch {
                engine = nil
                return
            }
        }
        guard !engineRunning, let engine else { return }
        do {
            try engine.start()
            engineRunning = true
        } catch {
            engineRunning = false
        }
    }

    /// (zaman, şiddet, keskinlik) üçlülerinden bir desen çalar. Çalamazsa false döner.
    private static func play(_ taps: [(time: TimeInterval, intensity: Float, sharpness: Float)]) -> Bool {
        guard supportsCoreHaptics else { return false }
        startEngineIfNeeded()
        guard engineRunning, let engine else { return false }
        do {
            let events = taps.map { t in
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: t.intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: t.sharpness)
                    ],
                    relativeTime: t.time
                )
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            engineRunning = false
            return false
        }
    }
}
