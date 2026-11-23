import SwiftUI

/// Oyun sahnesinden görev sistemine giden olaylar.
enum GameEvent {
    case perfect
    case driven(NailKind)
    case streak(Int)
    case levelComplete(level: Level, stars: Int, redHits: Int)
}

/// Günlük görev türleri. Her gün oyuncunun ilerlemesine uygun olanlardan 3 tanesi seçilir.
enum QuestKind: String, Codable, CaseIterable {
    case perfects, drive, streak, levels, boss, hard, gold, threeStars, noRed

    /// Bu görevin çıkabilmesi için açılmış olması gereken seviye
    var minUnlockedLevel: Int {
        switch self {
        case .perfects, .drive, .streak, .levels, .threeStars: return 1
        case .gold: return 4
        case .boss: return 5
        case .hard: return 7
        case .noRed: return 14
        }
    }

    var icon: String {
        switch self {
        case .perfects: return "scope"
        case .drive: return "hammer.fill"
        case .streak: return "flame.fill"
        case .levels: return "flag.checkered"
        case .boss: return "crown.fill"
        case .hard: return "bolt.fill"
        case .gold: return "dollarsign.circle.fill"
        case .threeStars: return "star.fill"
        case .noRed: return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .perfects: return .tkGreen
        case .boss, .noRed: return .tkRed
        case .streak, .hard: return .tkOrange
        case .drive, .levels, .gold, .threeStars: return .tkYellow
        }
    }

    func title(_ goal: Int) -> String {
        switch self {
        case .perfects: return "\(goal) mükemmel vuruş yap"
        case .drive: return "\(goal) çivi çak"
        case .streak: return "Tek oyunda \(goal)'lik seri yap"
        case .levels: return "\(goal) seviye geç"
        case .boss: return "Bir patron seviyesi geç"
        case .hard: return "\(goal) zorlu çivi göm"
        case .gold: return "\(goal) altın çivi göm"
        case .threeStars: return "Bir seviyeyi 3 yıldızla geç"
        case .noRed: return "Kırmızıya hiç vurmadan seviye geç"
        }
    }
}

struct Quest: Codable, Identifiable, Equatable {
    var id = UUID()
    let kind: QuestKind
    let goal: Int
    var progress = 0
    let rewardCoins: Int
    let rewardStars: Int
    var claimed = false

    var isComplete: Bool { progress >= goal }
    var canClaim: Bool { isComplete && !claimed }
    var title: String { kind.title(goal) }

    /// Oyuncunun ilerlemesine göre hedef ve ödül belirler.
    static func make(_ kind: QuestKind, unlocked: Int) -> Quest {
        let u = max(1, unlocked)
        func round5(_ v: Int) -> Int { max(5, (v / 5) * 5) }
        switch kind {
        case .perfects:
            let g = round5(20 + min(40, u * 2))
            return Quest(kind: kind, goal: g, rewardCoins: 60 + g, rewardStars: 0)
        case .drive:
            let g = round5(30 + min(60, u * 3))
            return Quest(kind: kind, goal: g, rewardCoins: 50 + g / 2, rewardStars: 0)
        case .streak:
            return Quest(kind: kind, goal: 8 + min(12, u / 2), rewardCoins: 100, rewardStars: 0)
        case .levels:
            return Quest(kind: kind, goal: u > 10 ? 3 : 2, rewardCoins: 90, rewardStars: 0)
        case .boss:
            return Quest(kind: kind, goal: 1, rewardCoins: 0, rewardStars: 2)
        case .hard:
            return Quest(kind: kind, goal: 3 + u / 8, rewardCoins: 100, rewardStars: 0)
        case .gold:
            return Quest(kind: kind, goal: 2 + u / 10, rewardCoins: 80, rewardStars: 0)
        case .threeStars:
            return Quest(kind: kind, goal: 1, rewardCoins: 0, rewardStars: 2)
        case .noRed:
            return Quest(kind: kind, goal: 1, rewardCoins: 120, rewardStars: 0)
        }
    }

    /// `exclude` dışındaki uygun türlerden rastgele `count` görev üretir.
    static func generate(count: Int, unlocked: Int, exclude: Set<QuestKind> = []) -> [Quest] {
        QuestKind.allCases
            .filter { $0.minUnlockedLevel <= unlocked && !exclude.contains($0) }
            .shuffled()
            .prefix(count)
            .map { make($0, unlocked: unlocked) }
    }

    /// Görevin bu olayla ilerleyip ilerlemediği; ilerlediyse yeni değeri döner.
    func advanced(by event: GameEvent) -> Int? {
        switch (kind, event) {
        case (.perfects, .perfect):
            return progress + 1
        case (.drive, .driven(let k)) where k != .red:
            return progress + 1
        case (.hard, .driven(.hard)):
            return progress + 1
        case (.gold, .driven(.gold)):
            return progress + 1
        case (.streak, .streak(let s)) where s > progress:
            return s
        case (.levels, .levelComplete):
            return progress + 1
        case (.boss, .levelComplete(let level, _, _)) where level.isBoss:
            return progress + 1
        case (.threeStars, .levelComplete(_, let stars, _)) where stars == 3:
            return progress + 1
        case (.noRed, .levelComplete(_, _, let red)) where red == 0:
            return progress + 1
        default:
            return nil
        }
    }
}
