import SwiftUI

/// Güçlendiriciler: seviyeden önce seçilir ya da oyun içinde kullanılır.
/// Bantta arada çıkan baloncuk çakılınca da bir tane kazanılır.
enum Powerup: String, CaseIterable, Codable, Identifiable {
    case zone, slow, life

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zone: return "Geniş bölge"
        case .slow: return "Yavaş çekim"
        case .life: return "+1 Can"
        }
    }

    /// Oyun içinde kullanınca ne yaptığı
    var inGameText: String {
        switch self {
        case .zone: return "8 sn vuruş bölgesi geniş"
        case .slow: return "5 sn bant yarı hızda"
        case .life: return "Bir can ekler"
        }
    }

    /// Seviyeden önce seçilince ne yaptığı
    var preLevelText: String {
        switch self {
        case .zone: return "İlk 10 sn"
        case .slow: return "5 sn, istediğin an"
        case .life: return "4 canla başla"
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
