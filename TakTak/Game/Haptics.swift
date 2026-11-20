import UIKit

/// Titreşim geri bildirimleri. Basit oyunu "iyi hissettiren" şeyin yarısı budur.
enum Haptics {
    static var enabled = true

    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() {
        guard enabled else { return }
        heavy.prepare()
        medium.prepare()
        notify.prepare()
    }

    /// Mükemmel vuruş: tok ve güçlü.
    static func perfect() {
        guard enabled else { return }
        heavy.impactOccurred(intensity: 1.0)
    }

    /// İyi vuruş: orta.
    static func good() {
        guard enabled else { return }
        medium.impactOccurred(intensity: 0.8)
    }

    /// Çivi eğildi.
    static func miss() {
        guard enabled else { return }
        notify.notificationOccurred(.error)
    }

    /// Menü dokunuşları, satın alma vb.
    static func tap() {
        guard enabled else { return }
        light.impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        notify.notificationOccurred(.success)
    }
}
