import Foundation
import SwiftUI

struct DailyState: Equatable {
    /// Serideki gün (1...7).
    let day: Int
    /// Bugün alınabilir mi?
    let canClaim: Bool
}

/// Oyuncunun kalıcı verileri (UserDefaults).
final class GameStore: ObservableObject {
    static let dailyRewards = [50, 75, 100, 150, 200, 300, 500]
    static let startingCoins = 100

    private let defaults = UserDefaults.standard

    @Published var coins: Int { didSet { defaults.set(coins, forKey: Keys.coins) } }
    @Published var best: Int { didSet { defaults.set(best, forKey: Keys.best) } }
    @Published var owned: Set<HammerVariant> { didSet { defaults.set(owned.map(\.rawValue), forKey: Keys.owned) } }
    @Published var equipped: HammerVariant { didSet { defaults.set(equipped.rawValue, forKey: Keys.equipped) } }
    @Published var soundOn: Bool {
        didSet {
            defaults.set(soundOn, forKey: Keys.sound)
            SoundFX.shared.enabled = soundOn
        }
    }
    @Published var hapticsOn: Bool {
        didSet {
            defaults.set(hapticsOn, forKey: Keys.haptics)
            Haptics.enabled = hapticsOn
        }
    }
    @Published private(set) var dailyDay: Int { didSet { defaults.set(dailyDay, forKey: Keys.dailyDay) } }
    @Published private(set) var lastClaim: Date? { didSet { defaults.set(lastClaim, forKey: Keys.lastClaim) } }

    private enum Keys {
        static let coins = "coins", best = "best", owned = "owned", equipped = "equipped"
        static let sound = "soundOn", haptics = "hapticsOn", dailyDay = "dailyDay", lastClaim = "lastClaim"
    }

    init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            Keys.coins: GameStore.startingCoins,
            Keys.sound: true,
            Keys.haptics: true
        ])
        coins = d.integer(forKey: Keys.coins)
        best = d.integer(forKey: Keys.best)
        let ownedRaw = d.stringArray(forKey: Keys.owned) ?? []
        owned = Set(ownedRaw.compactMap(HammerVariant.init(rawValue:))).union([.klasik])
        equipped = HammerVariant(rawValue: d.string(forKey: Keys.equipped) ?? "") ?? .klasik
        soundOn = d.bool(forKey: Keys.sound)
        hapticsOn = d.bool(forKey: Keys.haptics)
        dailyDay = d.integer(forKey: Keys.dailyDay)
        lastClaim = d.object(forKey: Keys.lastClaim) as? Date

        SoundFX.shared.enabled = soundOn
        Haptics.enabled = hapticsOn
    }

    // MARK: - Oyun sonu

    /// Kazanılan paraları ekler, rekoru günceller. Yeni rekor ise true döner.
    @discardableResult
    func finishRun(score: Int, coins earned: Int) -> Bool {
        coins += earned
        if score > best {
            best = score
            return true
        }
        return false
    }

    // MARK: - Mağaza

    enum SelectResult {
        case equipped, bought, notEnough(missing: Int), locked(need: Int)
    }

    func isUnlocked(_ h: HammerVariant) -> Bool {
        guard let need = h.unlockBest else { return true }
        return best >= need
    }

    func select(_ h: HammerVariant) -> SelectResult {
        if owned.contains(h) {
            equipped = h
            return .equipped
        }
        if let need = h.unlockBest, best < need {
            return .locked(need: need)
        }
        if coins < h.price {
            return .notEnough(missing: h.price - coins)
        }
        coins -= h.price
        owned.insert(h)
        equipped = h
        return .bought
    }

    // MARK: - Günlük ödül

    var dailyState: DailyState {
        let cal = Calendar.current
        guard let last = lastClaim, dailyDay > 0 else { return DailyState(day: 1, canClaim: true) }
        if cal.isDateInToday(last) { return DailyState(day: dailyDay, canClaim: false) }
        if cal.isDateInYesterday(last) { return DailyState(day: dailyDay % 7 + 1, canClaim: true) }
        return DailyState(day: 1, canClaim: true)
    }

    /// Ödülü verir. 7. günde sahip olunmayan rastgele bir çekiç de verir.
    func claimDaily() -> (coins: Int, hammer: HammerVariant?) {
        let state = dailyState
        guard state.canClaim else { return (0, nil) }
        let amount = Self.dailyRewards[state.day - 1]
        coins += amount
        var bonus: HammerVariant?
        if state.day == 7 {
            let candidates = HammerVariant.allCases.filter { !owned.contains($0) && $0.unlockBest == nil }
            if let h = candidates.randomElement() {
                owned.insert(h)
                bonus = h
            }
        }
        dailyDay = state.day
        lastClaim = Date()
        return (amount, bonus)
    }
}
