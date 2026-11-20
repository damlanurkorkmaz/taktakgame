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

    // Seviye ilerlemesi
    /// Açılmış en yüksek seviye (Level.count + 1 = hepsi bitti)
    @Published private(set) var unlockedLevel: Int { didSet { defaults.set(unlockedLevel, forKey: Keys.unlockedLevel) } }
    /// Seviye numarası -> en iyi yıldız sayısı
    @Published private(set) var levelStars: [Int: Int] {
        didSet {
            let dict = Dictionary(uniqueKeysWithValues: levelStars.map { (String($0.key), $0.value) })
            defaults.set(dict, forKey: Keys.levelStars)
        }
    }
    /// Sandıklara harcanmış yıldız sayısı
    @Published private(set) var chestStarsUsed: Int { didSet { defaults.set(chestStarsUsed, forKey: Keys.chestStarsUsed) } }
    /// Tanıtımı gösterilmiş yenilikler
    @Published private(set) var seenFeatures: Set<String> { didSet { defaults.set(Array(seenFeatures), forKey: Keys.seenFeatures) } }
    @Published private(set) var lastClaim: Date? { didSet { defaults.set(lastClaim, forKey: Keys.lastClaim) } }

    private enum Keys {
        static let coins = "coins", best = "best", owned = "owned", equipped = "equipped"
        static let sound = "soundOn", haptics = "hapticsOn", dailyDay = "dailyDay", lastClaim = "lastClaim"
        static let unlockedLevel = "unlockedLevel", levelStars = "levelStars"
        static let chestStarsUsed = "chestStarsUsed", seenFeatures = "seenFeatures"
    }

    init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            Keys.coins: GameStore.startingCoins,
            Keys.sound: true,
            Keys.haptics: true,
            Keys.unlockedLevel: 1
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
        unlockedLevel = max(1, d.integer(forKey: Keys.unlockedLevel))
        let rawStars = d.dictionary(forKey: Keys.levelStars) as? [String: Int] ?? [:]
        levelStars = Dictionary(uniqueKeysWithValues: rawStars.compactMap { k, v in Int(k).map { ($0, v) } })
        chestStarsUsed = d.integer(forKey: Keys.chestStarsUsed)
        seenFeatures = Set(d.stringArray(forKey: Keys.seenFeatures) ?? [])

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

    // MARK: - Seviyeler

    static let chestCost = 15
    static let chestCoins = 200

    /// Oynanacak sıradaki seviye
    var currentLevel: Int { min(unlockedLevel, Level.count) }
    var allLevelsDone: Bool { unlockedLevel > Level.count }
    var endlessUnlocked: Bool { unlockedLevel > Level.endlessUnlockLevel }
    var totalStars: Int { levelStars.values.reduce(0, +) }
    var chestProgress: Int { max(0, totalStars - chestStarsUsed) }
    var chestReady: Bool { chestProgress >= Self.chestCost }

    func stars(for level: Int) -> Int { levelStars[level] ?? 0 }

    func isLevelOpen(_ level: Int) -> Bool { level <= unlockedLevel }

    struct LevelResult {
        let newStars: Int
        let coins: Int
        let firstClear: Bool
    }

    /// Seviye geçildi: yıldızları ve paraları kaydeder, sıradaki seviyeyi açar.
    func completeLevel(_ level: Level, stars: Int, runCoins: Int) -> LevelResult {
        let previous = levelStars[level.number] ?? 0
        let firstClear = previous == 0
        let newStars = max(0, stars - previous)
        if stars > previous { levelStars[level.number] = stars }
        if level.number >= unlockedLevel { unlockedLevel = level.number + 1 }
        let bonus = newStars > 0 ? level.clearReward : 0
        coins += runCoins + bonus
        return LevelResult(newStars: newStars, coins: runCoins + bonus, firstClear: firstClear)
    }

    /// Seviye kaybedildi: o turda toplanan paralar yine de verilir.
    func failLevel(runCoins: Int) {
        coins += runCoins
    }

    /// Sandığı açar: para ve %30 ihtimalle sahip olunmayan bir çekiç.
    func openChest() -> (coins: Int, hammer: HammerVariant?) {
        guard chestReady else { return (0, nil) }
        chestStarsUsed += Self.chestCost
        coins += Self.chestCoins
        var hammer: HammerVariant?
        if Double.random(in: 0..<1) < 0.3 {
            let candidates = HammerVariant.allCases.filter { !owned.contains($0) && $0.unlockBest == nil }
            if let h = candidates.randomElement() {
                owned.insert(h)
                hammer = h
            }
        }
        return (Self.chestCoins, hammer)
    }

    func hasSeen(_ feature: Feature) -> Bool { seenFeatures.contains(feature.rawValue) }

    func markSeen(_ feature: Feature) { seenFeatures.insert(feature.rawValue) }

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
