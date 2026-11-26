import CoreGraphics

/// Seviye hedefi.
enum LevelGoal: Equatable {
    /// n çiviyi tamamen göm
    case drive(Int)
    /// n mükemmel vuruş yap
    case perfect(Int)
    /// n zorlu çivi göm
    case hard(Int)

    var count: Int {
        switch self {
        case .drive(let n), .perfect(let n), .hard(let n): return n
        }
    }

    /// "25 çivi çak"
    var title: String {
        switch self {
        case .drive(let n): return L("\(n) çivi çak", "Drive \(n) nails")
        case .perfect(let n): return L("\(n) mükemmel vuruş", "\(n) perfect hits")
        case .hard(let n): return L("\(n) zorlu çivi göm", "Drive \(n) tough nails")
        }
    }

    /// İlerleme çubuğundaki birim: "14 / 25 çivi"
    var unit: String {
        switch self {
        case .drive: return L("çivi", "nails")
        case .perfect: return L("mükemmel", "perfect")
        case .hard: return L("zorlu", "tough")
        }
    }
}

/// Seviyelerle kademeli olarak tanıtılan yenilikler.
enum Feature: String, CaseIterable {
    case gold, hard, pairs, red, tempo, plate, spring, ice, bomb

    var badge: String {
        switch self {
        case .gold, .hard, .red, .plate, .spring, .ice, .bomb: return L("YENİ ÇİVİ!", "NEW NAIL!")
        case .pairs, .tempo: return L("YENİ!", "NEW!")
        }
    }

    var title: String {
        switch self {
        case .gold: return L("Altın Çivi", "Golden Nail")
        case .hard: return L("Zorlu Çivi", "Tough Nail")
        case .pairs: return L("Çift Çivi", "Double Nails")
        case .red: return L("Kırmızı Çivi", "Red Nail")
        case .tempo: return L("Hız Dalgaları", "Speed Waves")
        case .plate: return L("Metal Levha", "Metal Plate")
        case .spring: return L("Yaylı Çivi", "Spring Nail")
        case .ice: return L("Buz Çivisi", "Ice Nail")
        case .bomb: return L("Bomba Çivi", "Bomb Nail")
        }
    }

    var text: String {
        switch self {
        case .gold: return L("Göm, +5 para kazan.", "Drive it in for +5 coins.")
        case .hard: return L("Kalın ve turuncu çizgili. Tam oturması için iki mükemmel vuruş ister. Gömünce +5 puan.", "Thick with orange stripes. Needs two perfect hits to sink. +5 points when driven.")
        case .pairs: return L("Bazen iki çivi art arda gelir. Hızlı ol!", "Sometimes two nails come back to back. Be quick!")
        case .red: return L("Buna vurma! Vurursan bir can gider. Bırak bant alıp götürsün.", "Don't hit this one! Hitting it costs a life. Let the belt carry it away.")
        case .tempo: return L("Bant ara ara hızlanır ve yavaşlar. Uyarıları takip et.", "The belt speeds up and slows down now and then. Watch for the warnings.")
        case .plate: return L("Sadece MÜKEMMEL vuruş işe yarar. İyi vuruşta çekiç seker; kenardan vurursan eğilir.", "Only a PERFECT hit works. On a good hit the hammer bounces off; hit the edge and it bends.")
        case .spring: return L("Vurulunca yarıya girer ama bir adım geri zıplar ve tekrar çekicin altına gelir. İkinci vuruşla tamamla.", "It sinks halfway, then springs back under the hammer. Finish it with a second hit.")
        case .ice: return L("Bant üstünde kayar: oka yaklaşırken aniden hızlanır ya da yavaşlar. Gözünü ayırma.", "It slides on the belt, suddenly speeding up or slowing down near the arrow. Keep your eyes on it.")
        case .bomb: return L("Tam vurursan patlar ve yanındaki 2 çiviyi de gömer. Kenardan vurursan bir can gider.", "A perfect hit blows it up and drives the 2 nails next to it. An edge hit costs a life.")
        }
    }

    /// Kısa açıklama (seviye hedefi kartındaki "YENİ" satırı)
    var short: String {
        switch self {
        case .gold: return L("Gömünce +5 para.", "+5 coins when driven.")
        case .hard: return L("İki tam vuruş ister, +5 puan bonus.", "Needs two perfect hits, +5 bonus points.")
        case .pairs: return L("İki çivi art arda gelebilir.", "Two nails may come back to back.")
        case .red: return L("Vurma! Vurursan can gider.", "Don't hit! It costs a life.")
        case .tempo: return L("Bant ara ara hızlanıp yavaşlar.", "The belt speeds up and slows down.")
        case .plate: return L("Sadece mükemmel vuruş işe yarar.", "Only perfect hits work.")
        case .spring: return L("Vurunca geri zıplar, iki vuruş ister.", "Springs back, needs two hits.")
        case .ice: return L("Bant üstünde kayar.", "Slides on the belt.")
        case .bomb: return L("Tam vur, yanındakileri de göm.", "Hit it perfectly to drive its neighbors too.")
        }
    }

    /// Tanıtım görselinde gösterilecek çivi
    var tint: NailTint {
        switch self {
        case .gold: return .gold
        case .hard: return .hard
        case .red: return .red
        case .plate: return .plate
        case .spring: return .spring
        case .ice: return .ice
        case .bomb: return .bomb
        case .pairs, .tempo: return .steel
        }
    }
}

/// Bir seviyenin bütün ayarları. 30 seviyelik ilk bölüm `Level.all` içinde kurallarla üretilir;
/// tek bir seviyeyi değiştirmek için `make(_:)` içindeki kurallara istisna eklemek yeterli.
struct Level: Identifiable, Equatable {
    let number: Int
    let goal: LevelGoal
    let startSpeed: CGFloat
    let maxSpeed: CGFloat
    let goldChance: Double
    let hardChance: Double
    let redChance: Double
    let plateChance: Double
    let springChance: Double
    let iceChance: Double
    let bombChance: Double
    let pairs: Bool
    let tempo: Bool
    let isBoss: Bool
    let newFeature: Feature?

    var id: Int { number }

    static let count = 30
    static var chapterTitle: String { L("ATÖLYE", "WORKSHOP") }
    static let all: [Level] = (1...count).map(make)

    static func get(_ number: Int) -> Level {
        all[max(1, min(count, number)) - 1]
    }

    /// Sonsuz mod 10. seviye geçilince açılır.
    static let endlessUnlockLevel = 10

    /// Yeniliklerin ilk çıktığı seviyeler
    static let featureLevels: [Int: Feature] = [
        3: .gold, 6: .hard, 8: .pairs, 13: .red, 16: .tempo,
        20: .plate, 22: .spring, 24: .ice, 27: .bomb
    ]

    private static func make(_ n: Int) -> Level {
        let boss = n % 5 == 0
        let hasGold = n >= 3
        let hasHard = n >= 6
        let hasRed = n >= 13

        // Hedef
        let goal: LevelGoal
        if n <= 2 {
            goal = .drive(10 + n * 3)
        } else if boss {
            goal = .drive(20 + n)
        } else if hasHard, n % 3 == 0 {
            goal = .hard(2 + n / 6)
        } else if n >= 4, n % 3 == 2 {
            goal = .perfect(8 + n / 2)
        } else {
            goal = .drive(15 + n)
        }

        // Hız (pt/sn)
        let start = min(140, 60 + CGFloat(n) * 3) + (boss ? 20 : 0)
        let maxSpeed = min(320, 140 + CGFloat(n) * 6) + (boss ? 20 : 0)

        // Çivi karışımı
        var hard = hasHard ? min(0.25, 0.10 + Double(n - 6) * 0.008) : 0
        if case .hard = goal { hard = max(hard, 0.22) }
        var red = hasRed ? min(0.15, 0.06 + Double(n - 13) * 0.005) : 0
        if boss {
            if hasHard { hard += 0.05 }
            if hasRed { red += 0.03 }
        }

        return Level(
            number: n,
            goal: goal,
            startSpeed: start,
            maxSpeed: maxSpeed,
            goldChance: hasGold ? 0.08 : 0,
            hardChance: hard,
            redChance: red,
            plateChance: n >= 20 ? (n == 20 ? 0.18 : 0.07) : 0,
            springChance: n >= 22 ? (n == 22 ? 0.18 : 0.07) : 0,
            iceChance: n >= 24 ? (n == 24 ? 0.18 : 0.07) : 0,
            bombChance: n >= 27 ? (n == 27 ? 0.14 : 0.05) : 0,
            pairs: n >= 8,
            tempo: n >= 16,
            isBoss: boss,
            newFeature: featureLevels[n]
        )
    }

    // MARK: - Yıldızlar

    static let twoStarAccuracy = 0.70
    static let threeStarAccuracy = 0.90
    static let threeStarStreak = 10

    static func stars(accuracy: Double, bestStreak: Int) -> Int {
        if accuracy >= threeStarAccuracy || bestStreak >= threeStarStreak { return 3 }
        if accuracy >= twoStarAccuracy { return 2 }
        return 1
    }

    /// İlk kez (ya da daha çok yıldızla) geçilince verilen para ödülü
    var clearReward: Int {
        15 + number * 2 + (isBoss ? 40 : 0)
    }
}
