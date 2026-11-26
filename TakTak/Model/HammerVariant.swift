import UIKit

enum HammerShape {
    case claw, sledge, mallet, crystal
}

struct HammerPalette {
    let shape: HammerShape
    let head: [UIColor]   // açık, orta, koyu
    let wood: [UIColor]   // açık, orta, koyu
    let grip: [UIColor]   // açık, koyu
    let gripLine: UIColor
    let glow: Bool
}

enum HammerVariant: String, CaseIterable, Identifiable, Codable {
    case klasik, tokmak, balyoz, altin, neon, kristal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .klasik: return L("Klasik", "Classic")
        case .tokmak: return L("Lastik Tokmak", "Rubber Mallet")
        case .balyoz: return L("Balyoz", "Sledgehammer")
        case .altin: return L("Altın Çekiç", "Golden Hammer")
        case .neon: return L("Neon", "Neon")
        case .kristal: return L("Kristal", "Crystal")
        }
    }

    /// Mağaza fiyatı (para). 0 = ücretsiz.
    var price: Int {
        switch self {
        case .klasik: return 0
        case .tokmak: return 800
        case .balyoz: return 1500
        case .altin: return 2000
        case .neon: return 3000
        case .kristal: return 0
        }
    }

    // MARK: - Çekiç güçleri

    /// Mağazada gösterilen güç açıklaması
    var power: String {
        switch self {
        case .klasik: return L("Standart çekiç, sürprizsiz.", "A trusty hammer. No surprises.")
        case .tokmak: return L("İyi bölgesi %20 daha geniş.", "Good zone is 20% wider.")
        case .balyoz: return L("Zorlu çiviyi tek tam vuruşta gömer.", "Drives tough nails in one perfect hit.")
        case .altin: return L("Her gömülen çivi +1 para.", "+1 coin for every nail driven.")
        case .neon: return L("Seri çarpanı 5 yerine 3 mükemmelde artar.", "Streak multiplier grows every 3 perfects, not 5.")
        case .kristal: return L("Mükemmel bölgesi %30 daha geniş.", "Perfect zone is 30% wider.")
        }
    }

    /// "İyi" penceresinin çarpanı
    var goodWindowScale: CGFloat { self == .tokmak ? 1.2 : 1 }
    /// "Mükemmel" penceresinin çarpanı
    var perfectWindowScale: CGFloat { self == .kristal ? 1.3 : 1 }
    /// Zorlu çivi tek mükemmel vuruşta gömülür
    var drivesHardInOne: Bool { self == .balyoz }
    /// Gömülen her çivi için ek para
    var coinBonus: Int { self == .altin ? 1 : 0 }
    /// Seri çarpanının kaç mükemmelde bir arttığı
    var streakStep: Int { self == .neon ? 3 : 5 }

    /// Açılması için gereken en iyi skor (nil = her zaman açık).
    var unlockBest: Int? {
        self == .kristal ? 250 : nil
    }

    var palette: HammerPalette {
        switch self {
        case .klasik:
            return HammerPalette(shape: .claw,
                                 head: [UIColor(hex: 0xF4F7FA), UIColor(hex: 0xA9B3BF), UIColor(hex: 0x5E6875)],
                                 wood: [UIColor(hex: 0xF6CB93), UIColor(hex: 0xD9984F), UIColor(hex: 0x9E6128)],
                                 grip: [UIColor(hex: 0x9A5530), UIColor(hex: 0x5E2F18)],
                                 gripLine: UIColor(hex: 0xD08A58), glow: false)
        case .altin:
            return HammerPalette(shape: .claw,
                                 head: [UIColor(hex: 0xFFF3B8), UIColor(hex: 0xF5B82E), UIColor(hex: 0x9C5F08)],
                                 wood: [UIColor(hex: 0xA8693A), UIColor(hex: 0x6E3D1A), UIColor(hex: 0x3E1E08)],
                                 grip: [UIColor(hex: 0xE0503F), UIColor(hex: 0x8E2018)],
                                 gripLine: UIColor(hex: 0xFFB3A6), glow: false)
        case .balyoz:
            return HammerPalette(shape: .sledge,
                                 head: [UIColor(hex: 0xA8B1BC), UIColor(hex: 0x5B6470), UIColor(hex: 0x2C3139)],
                                 wood: [UIColor(hex: 0xFFE07A), UIColor(hex: 0xF2B52B), UIColor(hex: 0xA87410)],
                                 grip: [UIColor(hex: 0x3A3A3A), UIColor(hex: 0x111111)],
                                 gripLine: UIColor(hex: 0x6A6A6A), glow: false)
        case .tokmak:
            return HammerPalette(shape: .mallet,
                                 head: [UIColor(hex: 0x6A6A6A), UIColor(hex: 0x2F2F2F), UIColor(hex: 0x121212)],
                                 wood: [UIColor(hex: 0xF6CB93), UIColor(hex: 0xD9984F), UIColor(hex: 0x9E6128)],
                                 grip: [UIColor(hex: 0x3A7BC0), UIColor(hex: 0x1C4A7A)],
                                 gripLine: UIColor(hex: 0x8FC0F0), glow: false)
        case .neon:
            return HammerPalette(shape: .claw,
                                 head: [UIColor(hex: 0x667386), UIColor(hex: 0x2E3644), UIColor(hex: 0x12161D)],
                                 wood: [UIColor(hex: 0x454C59), UIColor(hex: 0x23272F), UIColor(hex: 0x0E1013)],
                                 grip: [UIColor(hex: 0x1D3B36), UIColor(hex: 0x0B1A17)],
                                 gripLine: UIColor(hex: 0x5FF5C8), glow: true)
        case .kristal:
            return HammerPalette(shape: .crystal,
                                 head: [UIColor(hex: 0xEAF8FF), UIColor(hex: 0x8FD3FF), UIColor(hex: 0x2F7FC4)],
                                 wood: [UIColor(hex: 0xF7F9FB), UIColor(hex: 0xC3CCD6), UIColor(hex: 0x7D8A9A)],
                                 grip: [UIColor(hex: 0x6A5ED0), UIColor(hex: 0x352C80)],
                                 gripLine: UIColor(hex: 0xB4ADF5), glow: false)
        }
    }
}
