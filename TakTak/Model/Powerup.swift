import SwiftUI

/// Güçlendiriciler: seviyeden önce seçilir ya da oyun içinde kullanılır.
/// Bantta arada çıkan baloncuk çakılınca da bir tane kazanılır.
enum Powerup: String, CaseIterable, Codable, Identifiable {
    case zone, slow, life

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zone: return L("Geniş bölge", "Wide zone")
        case .slow: return L("Yavaş çekim", "Slow-mo")
        case .life: return L("+1 Can", "+1 Life")
        }
    }

    /// Oyun içinde kullanınca ne yaptığı
    var inGameText: String {
        switch self {
        case .zone: return L("8 sn vuruş bölgesi geniş", "Wider hit zone for 8s")
        case .slow: return L("5 sn bant yarı hızda", "Belt at half speed for 5s")
        case .life: return L("Bir can ekler", "Adds one life")
        }
    }

    /// Seviyeden önce seçilince ne yaptığı
    var preLevelText: String {
        switch self {
        case .zone: return L("İlk 10 sn", "First 10s")
        case .slow: return L("5 sn, istediğin an", "5s, whenever you want")
        case .life: return L("4 canla başla", "Start with 4 lives")
        }
    }

    var icon: String {
        switch self {
        case .zone: return "arrow.left.and.right"
        case .slow: return "timer"
        case .life: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .zone: return .tkGreen
        case .slow: return Color(hex: 0x7CC8F5)
        case .life: return .tkRed
        }
    }

    var uiColor: UIColor {
        switch self {
        case .zone: return Palette.green
        case .slow: return UIColor(hex: 0x7CC8F5)
        case .life: return Palette.red
        }
    }

    /// Mağaza / seviye öncesi fiyatı (para)
    var price: Int {
        switch self {
        case .zone: return 100
        case .slow: return 150
        case .life: return 200
        }
    }

    /// Etkinin süresi (sn); can için 0
    var duration: TimeInterval {
        switch self {
        case .zone: return 8
        case .slow: return 5
        case .life: return 0
        }
    }
}
