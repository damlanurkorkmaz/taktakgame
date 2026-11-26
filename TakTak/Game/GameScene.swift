import SpriteKit
import UIKit

/// Oyunun kalbi.
///
/// Bant sürekli sola akar, üstündeki çiviler çekicin altından geçer.
/// Oyuncu, çivi sarı okun üstüne geldiği anda dokunur:
/// - Tam ortadaysa **mükemmel**: çivi tek vuruşta gömülür, 3 puan × seri çarpanı.
/// - Biraz kaymışsa **iyi**: çivi yarıya girer, 2 puan, seri sıfırlanır.
/// - Kenardan vurulursa çivi **eğri** girer: 1 puan, seri sıfırlanır.
/// - Hiç vurulmadan geçen çivi **kaçar**: bir can gider.
/// - **Kırmızı** çiviye vurulursa bir can gider; geçmesine izin verilmeli.
/// Özel çiviler: metal levha (yalnızca mükemmel), yaylı (geri zıplar), buz (kayar),
/// bomba (tam vurunca yanındakileri de gömer, kenardan vurunca can gider).
/// Bantta arada güçlendirici baloncukları gelir; vurulunca toplanır.
///
/// İki mod vardır: **seviye** (hedefe ulaşınca biter, ayarlar `Level`'dan gelir) ve
/// **sonsuz** (can bitene kadar, zorluk çivi sayısına göre artar).
final class GameScene: SKScene, ObservableObject {

    enum LossReason { case escaped, red, bomb }

    static let maxLives = 3
    static let lifeCap = 5

    // MARK: - SwiftUI'ye yayınlanan durum

    @Published private(set) var score = 0
    @Published private(set) var multiplier = 1
    @Published private(set) var runCoins = 0
    @Published private(set) var lives = GameScene.maxLives
    @Published private(set) var isOver = false
    @Published private(set) var isComplete = false
    @Published private(set) var hasContinued = false
    @Published private(set) var lastLoss: LossReason = .escaped
    /// Seviye hedefine doğru ilerleme
    @Published private(set) var progress = 0
    /// Etkin güçlendiricilerin kalan süre oranı (0...1); etkin değilse 0
    @Published private(set) var zoneLeft: Double = 0
    @Published private(set) var slowLeft: Double = 0

    /// Seviye modunda oynanan seviye; sonsuz modda nil.
    let level: Level?
    /// İlk açılış eğitimi: bant yavaş, L("ŞİMDİ DOKUN!", "TAP NOW!") yardımı açık
    let tutorial: Bool

    /// Görev sistemi için olaylar (mükemmel vuruş, gömülen çivi, seri).
    var onEvent: ((GameEvent) -> Void)?
    /// Banttaki baloncuktan güçlendirici toplandı
    var onPowerupCollected: ((Powerup) -> Void)?

    // MARK: - Tur istatistikleri (yıldız hesabı için)

    private(set) var perfects = 0
    private(set) var goods = 0
    private(set) var weaks = 0
    private(set) var escapes = 0
    private(set) var redHits = 0
    private(set) var woodHits = 0
    private(set) var bestStreak = 0

    /// 0...1 isabet: mükemmel 1, iyi 0.6, eğri 0.25; kaçan, kırmızıya ve boşa vuruş 0.
    var accuracy: Double {
        let attempts = perfects + goods + weaks + escapes + redHits + woodHits
        guard attempts > 0 else { return 0 }
        let value = Double(perfects) + Double(goods) * 0.6 + Double(weaks) * 0.25
        return value / Double(attempts)
    }

    // MARK: - Oyun dengesi

    private enum Tuning {
        // Bant hızı (pt/sn) — sonsuz mod
        static let startSpeed: CGFloat = 70
        static let maxSpeed: CGFloat = 300
        static let perfectBoost: CGFloat = 3.5
        static let goodBoost: CGFloat = 1.5
        static let lossSlowdown: CGFloat = 22
        static let tutorialSpeed: CGFloat = 50

        // Tempo dalgaları: bant hızı bu katsayılarla çarpılır, geçişler kademeli
        static let tempos: [CGFloat] = [0.8, 1.0, 1.0, 1.25]
        static let tempoDuration: ClosedRange<TimeInterval> = 6...10
        static let tempoEase: CGFloat = 0.5
        static let tempoAfter = 8

        // Vuruş anında çivinin çekiç eksenine uzaklığı (pt)
        static let perfectWindow: CGFloat = 10
        static let goodWindow: CGFloat = 26
        static let bendMargin: CGFloat = 14
        static let zoneBoost: CGFloat = 1.6         // Geniş bölge güçlendiricisi
        static let slowFactor: CGFloat = 0.5        // Yavaş çekim güçlendiricisi

        // Çivi aralığı
        static let minReaction: CGFloat = 0.55
        static let minGap: CGFloat = 70
        static let extraGap: ClosedRange<CGFloat> = 0...130
        static let pairAfter = 25
        static let pairChance = 0.12
        static let pairReaction: CGFloat = 0.35

        // Sonsuz modda çivi türleri
        static let goldChance = 0.08
        static let hardAfter = 12
        static let hardChanceBase = 0.15
        static let hardChanceMax = 0.28
        static let redAfter = 40
        static let redChance = 0.08
        static let specialAfter = 60                // metal, yaylı, buz, bomba
        static let specialChance = 0.05             // her biri için
        static let bubbleChance = 0.04
        static let bubbleAfter = 6

        // Özel çiviler
        static let springBack: CGFloat = 80         // yaylı çivinin geri zıplama mesafesi
        static let iceSlips: [CGFloat] = [-0.45, -0.3, 0.35, 0.5]
        static let bombRadius: CGFloat = 260
        static let bombBonus = 10

        // Puan ve para
        static let perfectPoints = 3
        static let goodPoints = 2
        static let weakPoints = 1
        static let hardBonus = 5
        static let plateBonus = 5
        static let maxMultiplier = 5
        static let goldCoins = 5
        static let hardCoins = 2
    }

    // MARK: - Yerleşim (genişlik 390, SpriteKit'te y yukarı)

    /// Tahtanın üst yüzeyi. Altta güçlendirici butonlarına yer kalsın diye yukarıda.
    private let surfaceY: CGFloat = 290
    private let hammerX: CGFloat = 195
    private let nailSize: CGFloat = 80
    private let hammerSize: CGFloat = 260
    private let restAngle: CGFloat = 0.47
    private var bottomLabelY: CGFloat { surfaceY - 148 }

    // MARK: - Düğümler

    private let world = SKNode()
    private let track = SKNode()
    private var hammer: SKSpriteNode?
    private var tiles: [Int: SKSpriteNode] = [:]
    private var nails: [NailNode] = []
    private var hintLabel: SKLabelNode?
    private var goodBeam: SKSpriteNode?
    private var perfectBeam: SKSpriteNode?
    private var assistNode: SKNode?

    // MARK: - Durum

    private var hammerVariant: HammerVariant = .klasik
    private var built = false
    private var running = false
    private var striking = false
    private var started = false
    private var beltSpeed: CGFloat = Tuning.startSpeed
    private var tempo: CGFloat = 1
    private var tempoTarget: CGFloat = 1
    private var tempoTimer: TimeInterval = 0
    private var nextSpawnX: CGFloat = 0
    private var spawned = 0
    private var streak = 0
    private var lastTime: TimeInterval = 0
    private var zoneTime: TimeInterval = 0
    private var slowTime: TimeInterval = 0
    private var assistLeft = 0
    private let startBoosts: Set<Powerup>

    private var startSpeed: CGFloat {
        if tutorial { return Tuning.tutorialSpeed }
        return level?.startSpeed ?? Tuning.startSpeed
    }
    private var maxSpeed: CGFloat {
        if tutorial { return 75 }
        return level?.maxSpeed ?? Tuning.maxSpeed
    }
    private var tempoEnabled: Bool { level?.tempo ?? (spawned >= Tuning.tempoAfter) }
    private var pairsEnabled: Bool { level?.pairs ?? (spawned > Tuning.pairAfter) }
    /// Bandın gerçek hızı: performansa bağlı hız × tempo dalgası × yavaş çekim.
    private var currentSpeed: CGFloat {
        let slow: CGFloat = slowTime > 0 ? Tuning.slowFactor : 1
        return min(maxSpeed * 1.15, beltSpeed * tempo) * slow
    }

    // Çekiç gücü ve geniş bölge güçlendiricisiyle vuruş pencereleri
    private var zoneScale: CGFloat { zoneTime > 0 ? Tuning.zoneBoost : 1 }
    private var perfectWindow: CGFloat { Tuning.perfectWindow * hammerVariant.perfectWindowScale * zoneScale }
    private var goodWindow: CGFloat { max(perfectWindow + 8, Tuning.goodWindow * hammerVariant.goodWindowScale * zoneScale) }
    private var bendWindow: CGFloat { goodWindow + Tuning.bendMargin }

    init(hammer: HammerVariant, level: Level?, boosts: Set<Powerup> = [], tutorial: Bool = false) {
        self.level = level
        self.tutorial = tutorial
        self.startBoosts = boosts
        super.init(size: CGSize(width: 390, height: 844))
        hammerVariant = hammer
        scaleMode = .aspectFill
        backgroundColor = Palette.bg
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    override func didMove(to view: SKView) {
        guard !built else { return }
        built = true
        // Genişlik hep 390; yükseklik ekran oranına uyar. Oyun öğeleri alttan yerleştiği için
        // farklı iPhone boylarında kırpılma olmaz.
        let b = view.bounds.size
        if b.width > 0, b.height > 0 {
            size = CGSize(width: 390, height: max(640, 390 * b.height / b.width))
        }
        view.isMultipleTouchEnabled = false
        build()
        resetRun()
        Haptics.prepare()
    }

    // MARK: - Kurulum

    private func build() {
        addChild(world)

        let frameNode = SKSpriteNode(texture: SKTexture(image: BeltArt.frameImage(marker: true)))
        frameNode.size = CGSize(width: BeltArt.unitWidth, height: BeltArt.fullHeight)
        frameNode.anchorPoint = CGPoint(x: 0.5, y: 1)
        frameNode.position = CGPoint(x: 195, y: surfaceY + BeltArt.surfaceY)
        frameNode.zPosition = 1
        world.addChild(frameNode)

        track.zPosition = 2
        world.addChild(track)

        // Vuruş bölgesini gösteren hafif ışık: dış kısım "iyi", orta kısım "mükemmel".
        let good = SKSpriteNode(color: Palette.yellow.withAlphaComponent(0.07),
                                size: CGSize(width: goodWindow * 2, height: 120))
        good.anchorPoint = CGPoint(x: 0.5, y: 0)
        good.position = CGPoint(x: hammerX, y: surfaceY)
        good.zPosition = 2.5
        world.addChild(good)
        goodBeam = good
        let perfect = SKSpriteNode(color: Palette.green.withAlphaComponent(0.12),
                                   size: CGSize(width: perfectWindow * 2, height: 120))
        perfect.anchorPoint = CGPoint(x: 0.5, y: 0)
        perfect.position = CGPoint(x: hammerX, y: surfaceY)
        perfect.zPosition = 2.6
        world.addChild(perfect)
        perfectBeam = perfect

        // Çekiç: dik çizilir, sapın ucundan döner. 90° döndüğünde başı çivinin üstüne iner.
        let h = SKSpriteNode(texture: hammerTexture())
        h.size = CGSize(width: hammerSize, height: hammerSize)
        h.anchorPoint = CGPoint(x: 0.5, y: 1 - HammerArt.pivot.y / 200)
        let k = hammerSize / 200
        // Dik çizimde başın yüzü pivottan 107.4 yukarıda, vuran yüz 64 solda.
        let upNailHeadTop = surfaceY + nailSize * NailArt.headTopRatio(.up)
        h.position = CGPoint(x: hammerX + 107.4 * k, y: upNailHeadTop + 64 * k)
        h.zRotation = restAngle
        h.zPosition = 10
        world.addChild(h)
        hammer = h

        let hint = SKLabelNode(fontNamed: TKFont.extraBoldName)
        hint.text = L("Çivi sarı okun üstüne gelince dokun", "Tap when the nail is over the yellow arrow")
        hint.fontSize = 15
        hint.fontColor = Palette.muted
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 195, y: bottomLabelY)
        hint.zPosition = 30
        addChild(hint)
        hintLabel = hint

        // Eğitim yardımı: çivi tam yerindeyken yanıp sönen L("ŞİMDİ DOKUN!", "TAP NOW!")
        let assist = SKNode()
        assist.position = CGPoint(x: hammerX, y: surfaceY + 150)
        assist.zPosition = 40
        assist.alpha = 0
        let assistLabel = SKLabelNode(fontNamed: TKFont.displayName)
        assistLabel.text = L("ŞİMDİ DOKUN!", "TAP NOW!")
        assistLabel.fontSize = 34
        assistLabel.fontColor = Palette.yellow
        assistLabel.verticalAlignmentMode = .center
        let assistShadow = SKLabelNode(fontNamed: TKFont.displayName)
        assistShadow.text = L("ŞİMDİ DOKUN!", "TAP NOW!")
        assistShadow.fontSize = 34
        assistShadow.fontColor = Palette.brownShadow
        assistShadow.verticalAlignmentMode = .center
        assistShadow.position = CGPoint(x: 0, y: -3)
        assist.addChild(assistShadow)
        assist.addChild(assistLabel)
        addChild(assist)
        assistNode = assist
    }

    private func hammerTexture() -> SKTexture {
        SKTexture(image: HammerArt.image(hammerVariant, size: hammerSize, angle: 0, shadow: false))
    }

    // MARK: - Dışarıdan çağrılanlar

    func restart() {
        resetRun()
    }

    /// "Devam et": bir can verir, çekicin önündeki çivileri temizler. Oyun başına bir kez.
    func revive() {
        guard isOver, !hasContinued else { return }
        hasContinued = true
        for nail in nails where !nail.resolved && worldX(nail) < hammerX + 220 {
            nail.resolved = true
            nail.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        }
        lives = 1
        streak = 0
        multiplier = 1
        striking = false
        hammer?.removeAllActions()
        hammer?.zRotation = restAngle
        startIdle()
        isOver = false
        running = true
    }

    /// Oyun sonu ekranı paraları kaydettikten sonra çağırır (devam edilirse iki kez sayılmasın).
    func consumeRunCoins() {
        runCoins = 0
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        lastTime = 0
    }

    /// Oyun içinde bir güçlendirici kullanır. Kullanılamıyorsa false döner.
    @discardableResult
    func use(_ p: Powerup) -> Bool {
        guard running, !isOver, !isComplete else { return false }
        switch p {
        case .life:
            guard lives < GameScene.lifeCap else { return false }
            lives += 1
            popup(L("+1 CAN", "+1 LIFE"), color: Palette.red, size: 32, at: CGPoint(x: 195, y: surfaceY + 190), rotation: 0, shadowColor: Palette.redShadow)
        case .zone:
            zoneTime = max(zoneTime, p.duration)
            popup(L("GENİŞ BÖLGE!", "WIDE ZONE!"), color: Palette.green, size: 30, at: CGPoint(x: 195, y: surfaceY + 190), rotation: 0, shadowColor: Palette.greenShadow)
        case .slow:
            slowTime = max(slowTime, p.duration)
            popup(L("YAVAŞ ÇEKİM!", "SLOW-MO!"), color: p.uiColor, size: 30, at: CGPoint(x: 195, y: surfaceY + 190), rotation: 0, shadowColor: nil)
        }
        Haptics.success()
        SoundFX.shared.play(.coin)
        updateBoostDisplay()
        return true
    }

    // MARK: - Tur sıfırlama

    private func resetRun() {
        removeAction(forKey: "gameOver")
        removeAction(forKey: "complete")
        nails.forEach { $0.removeFromParent() }
        nails.removeAll()
        tiles.values.forEach { $0.removeFromParent() }
        tiles.removeAll()
        track.removeAllActions()
        track.position = .zero
        world.removeAllActions()
        world.position = .zero

        score = 0
        multiplier = 1
        runCoins = 0
        lives = GameScene.maxLives + (startBoosts.contains(.life) ? 1 : 0)
        isOver = false
        isComplete = false
        hasContinued = false
        lastLoss = .escaped
        progress = 0
        perfects = 0
        goods = 0
        weaks = 0
        escapes = 0
        redHits = 0
        woodHits = 0
        bestStreak = 0
        beltSpeed = startSpeed
        tempo = 1
        tempoTarget = 1
        tempoTimer = TimeInterval.random(in: Tuning.tempoDuration)
        zoneTime = startBoosts.contains(.zone) ? 10 : 0
        slowTime = 0
        spawned = 0
        streak = 0
        lastTime = 0
        started = false
        striking = false
        running = true
        assistLeft = tutorial ? 4 : 0

        hintLabel?.removeAllActions()
        hintLabel?.alpha = 1
        assistNode?.removeAllActions()
        assistNode?.alpha = 0
        hammer?.removeAllActions()
        hammer?.texture = hammerTexture()
        hammer?.zRotation = restAngle
        startIdle()
        updateBoostDisplay()

        // Geride, daha önce çakılmış gibi duran süs çivileri
        for offset in [CGFloat(-110), -220] {
            let n = makeNail(kind: .normal, at: hammerX + offset)
            n.setDriven()
            n.resolved = true
        }
        nextSpawnX = hammerX + 230
        refreshTiles()
        spawnIfNeeded()
    }

    // MARK: - Döngü

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : CGFloat(min(currentTime - lastTime, 1.0 / 30.0))
        lastTime = currentTime
        guard running, !isOver else { return }

        if zoneTime > 0 || slowTime > 0 {
            zoneTime = max(0, zoneTime - TimeInterval(dt))
            slowTime = max(0, slowTime - TimeInterval(dt))
            updateBoostDisplay()
        }
        updateTempo(dt)
        track.position.x -= currentSpeed * dt
        slideIce(dt)
        refreshTiles()
        spawnIfNeeded()
        checkPassed()
        updateAssist()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tap()
    }

    /// Güçlendirici süre çubuklarını ve vuruş ışığını günceller (yalnızca belirgin değişimde yayınlar).
    private func updateBoostDisplay() {
        let z = zoneTime > 0 ? zoneTime / Powerup.zone.duration : 0
        let s = slowTime > 0 ? slowTime / Powerup.slow.duration : 0
        if abs(z - zoneLeft) > 0.02 || (z == 0) != (zoneLeft == 0) { zoneLeft = min(1, z) }
        if abs(s - slowLeft) > 0.02 || (s == 0) != (slowLeft == 0) { slowLeft = min(1, s) }
        goodBeam?.size.width = goodWindow * 2
        perfectBeam?.size.width = perfectWindow * 2
        goodBeam?.color = (zoneTime > 0 ? Palette.green : Palette.yellow).withAlphaComponent(zoneTime > 0 ? 0.12 : 0.07)
    }

    // MARK: - Bant ve çiviler

    private func worldX(_ nail: NailNode) -> CGFloat {
        nail.position.x + track.position.x
    }

    private func refreshTiles() {
        let tx = track.position.x
        let first = Int(floor((-80 - tx) / BeltArt.unitWidth))
        let last = Int(floor((size.width + 80 - tx) / BeltArt.unitWidth))
        for i in first...last where tiles[i] == nil {
            let tile = SKSpriteNode(texture: SKTexture(image: BeltArt.trackImage()))
            tile.size = CGSize(width: BeltArt.unitWidth + 0.5, height: BeltArt.fullHeight)
            tile.anchorPoint = CGPoint(x: 0, y: 1)
            tile.position = CGPoint(x: CGFloat(i) * BeltArt.unitWidth, y: surfaceY + BeltArt.surfaceY)
            track.addChild(tile)
            tiles[i] = tile
        }
        for (i, tile) in tiles where i < first || i > last {
            tile.removeFromParent()
            tiles[i] = nil
        }
    }

    private func spawnIfNeeded() {
        while nextSpawnX + track.position.x < size.width + 60 {
            makeNail(kind: nextKind(), at: nextSpawnX)
            spawned += 1
            nextSpawnX += nextGap()
        }
    }

    private func nextKind() -> NailKind {
        // İlk iki çivi her zaman normal: oyuncu ısınsın.
        guard spawned >= 2, !tutorial else { return .normal }
        var table: [(NailKind, Double)] = []
        if let level {
            table = [(.hard, level.hardChance), (.red, level.redChance), (.gold, level.goldChance),
                     (.plate, level.plateChance), (.spring, level.springChance),
                     (.ice, level.iceChance), (.bomb, level.bombChance)]
        } else {
            let hard = spawned >= Tuning.hardAfter
                ? min(Tuning.hardChanceMax, Tuning.hardChanceBase + Double(spawned) * 0.002) : 0
            let special = spawned >= Tuning.specialAfter ? Tuning.specialChance : 0
            table = [(.hard, hard), (.red, spawned >= Tuning.redAfter ? Tuning.redChance : 0),
                     (.gold, spawned >= 3 ? Tuning.goldChance : 0),
                     (.plate, special), (.spring, special), (.ice, special), (.bomb, special * 0.8)]
        }
        if spawned >= Tuning.bubbleAfter {
            table.append((.bubble(Powerup.allCases.randomElement() ?? .zone), Tuning.bubbleChance))
        }
        var r = Double.random(in: 0..<1)
        for (kind, chance) in table {
            if r < chance {
                // Arka arkaya iki kırmızı ya da iki baloncuk gelmesin
                if kind == .red, nails.last?.kind == .red { return .normal }
                if kind.isBubble, nails.last?.kind.isBubble == true { return .normal }
                return kind
            }
            r -= chance
        }
        return .normal
    }

    private func nextGap() -> CGFloat {
        if pairsEnabled, Double.random(in: 0..<1) < Tuning.pairChance,
           nails.last?.kind != .red, nails.last?.kind != .spring {
            return max(60, currentSpeed * Tuning.pairReaction)
        }
        let minGap = max(Tuning.minGap, currentSpeed * Tuning.minReaction)
        // Yaylı çivi geri zıplayacağı için arkasında boşluk bırak
        let springRoom: CGFloat = nails.last?.kind == .spring ? Tuning.springBack : 0
        return minGap + springRoom + CGFloat.random(in: Tuning.extraGap)
    }

    @discardableResult
    private func makeNail(kind: NailKind, at x: CGFloat) -> NailNode {
        let n = NailNode(kind: kind, size: nailSize)
        n.position = CGPoint(x: x, y: surfaceY + (kind.isBubble ? 26 : 0))
        n.zPosition = 3
        if kind == .ice {
            n.slip = Tuning.iceSlips.randomElement() ?? 0.4
        }
        if kind.isBubble {
            n.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 6, duration: 0.5),
                .moveBy(x: 0, y: -6, duration: 0.5)
            ])), withKey: "float")
        }
        track.addChild(n)
        nails.append(n)
        return n
    }

    /// Buz çivileri oka yaklaşırken bant üstünde kayar (hızlanır ya da yavaşlar).
    private func slideIce(_ dt: CGFloat) {
        for nail in nails where nail.kind == .ice && !nail.resolved {
            let x = worldX(nail)
            guard x > hammerX + 15, x < hammerX + 170 else { continue }
            if !nail.glinted {
                nail.glinted = true
                nail.run(.sequence([
                    .colorize(with: .white, colorBlendFactor: 0.6, duration: 0.08),
                    .colorize(withColorBlendFactor: 0, duration: 0.15)
                ]))
            }
            nail.position.x += nail.slip * currentSpeed * dt
        }
    }

    /// Çekicin altından geçip giden çivileri sonuçlandırır.
    private func checkPassed() {
        for nail in nails where !nail.resolved && worldX(nail) < hammerX - bendWindow {
            nail.resolved = true
            if nail.kind.isBubble { continue }
            if nail.kind == .red {
                // Kırmızıyı bırakmak doğru hamle
                if nail.depth == 0 {
                    popup(L("GÜZEL!", "NICE!"), color: Palette.green, size: 24, at: CGPoint(x: 90, y: surfaceY + 152), shadowColor: nil)
                }
                continue
            }
            // Vurulmuş ama yarım kalmış çivi cezasız geçer; hiç vurulmamış çivi kaçar.
            guard nail.depth == 0 else { continue }
            escapes += 1
            popup(L("KAÇTI!", "MISSED!"), color: Palette.red, size: 34, at: CGPoint(x: 90, y: surfaceY + 160), shadowColor: Palette.redShadow)
            loseLife(.escaped)
            if lives <= 0 { break }
        }
        nails.removeAll { nail in
            if worldX(nail) < -60 {
                nail.removeFromParent()
                return true
            }
            return false
        }
    }

    /// Çekicin altına en yakın, henüz sonuçlanmamış çivi.
    private func target(within maxDistance: CGFloat) -> NailNode? {
        nails
            .filter { !$0.resolved && abs(worldX($0) - hammerX) <= maxDistance }
            .min { abs(worldX($0) - hammerX) < abs(worldX($1) - hammerX) }
    }

    // MARK: - Eğitim yardımı

    private func updateAssist() {
        guard let assistNode else { return }
        let show = assistLeft > 0 && target(within: perfectWindow + 6).map { !$0.kind.isBubble && $0.kind != .red } == true
        if show && assistNode.alpha == 0 {
            assistNode.removeAllActions()
            assistNode.alpha = 1
            assistNode.setScale(0.6)
            assistNode.run(.scale(to: 1, duration: 0.1))
        } else if !show && assistNode.alpha > 0 {
            assistNode.removeAllActions()
            assistNode.alpha = 0
        }
    }

    // MARK: - Vuruş

    private func tap() {
        guard running, !isOver, !isComplete, !striking, let hammer else { return }

        if !started {
            started = true
            if !tutorial {
                hintLabel?.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.4)]))
            }
        }

        striking = true
        let aim = target(within: bendWindow + 30)
        let angle: CGFloat = aim?.state == .half ? 103 * .pi / 180 : .pi / 2

        hammer.removeAllActions()
        let down = SKAction.rotate(toAngle: angle, duration: 0.05, shortestUnitArc: false)
        down.timingMode = .easeIn
        let up = SKAction.rotate(toAngle: restAngle, duration: 0.12, shortestUnitArc: false)
        up.timingMode = .easeOut

        hammer.run(.sequence([
            down,
            .run { [weak self] in
                self?.impact()
                self?.striking = false
            },
            .wait(forDuration: 0.03),
            up,
            .run { [weak self] in self?.startIdle() }
        ]))
    }

    private func impact() {
        guard running else { return }
        guard let nail = target(within: bendWindow) else {
            hitWood()
            return
        }
        if case .bubble(let p) = nail.kind {
            collect(nail, p)
            return
        }
        if nail.kind == .red {
            hitRed(nail)
            return
        }
        let dx = abs(worldX(nail) - hammerX)
        if dx <= perfectWindow {
            perfectHit(nail)
        } else if dx <= goodWindow {
            goodHit(nail)
        } else {
            bend(nail)
        }
    }

    private func perfectHit(_ nail: NailNode) {
        perfects += 1
        streak += 1
        bestStreak = max(bestStreak, streak)
        multiplier = min(Tuning.maxMultiplier, 1 + streak / hammerVariant.streakStep)
        onEvent?(.perfect)
        onEvent?(.streak(streak))
        let points = Tuning.perfectPoints * multiplier
        score += points
        beltSpeed = min(maxSpeed, beltSpeed + Tuning.perfectBoost)

        popup(L("MÜKEMMEL!", "PERFECT!"), color: Palette.yellow, size: 46, at: CGPoint(x: 140, y: surfaceY + 170))
        popup("+\(points)", color: Palette.green, size: 26, at: CGPoint(x: 140, y: surfaceY + 126), rotation: -0.1, shadowColor: nil)
        shake(amount: 8)
        Haptics.perfect()
        SoundFX.shared.play(.perfect)
        if case .perfect = level?.goal { addProgress(1) }

        if nail.kind == .bomb {
            explode(nail)
            return
        }
        if nail.kind == .spring && !nail.bounced {
            springBack(nail)
            return
        }
        let amount = (nail.kind == .hard && hammerVariant.drivesHardInOne) ? 4 : 2
        let done = nail.hit(amount)
        sparks(at: CGPoint(x: hammerX, y: surfaceY + (done ? 10 : 36)), count: 12, color: Palette.yellow)
        if done { finish(nail) }
    }

    private func goodHit(_ nail: NailNode) {
        streak = 0
        multiplier = 1
        if nail.kind == .plate {
            // Metal levha: yalnızca mükemmel vuruş işe yarar
            woodHits += 1
            popup(L("SEKTİ!", "BOUNCED!"), color: Palette.muted, size: 34, at: CGPoint(x: 130, y: surfaceY + 160))
            sparks(at: CGPoint(x: hammerX, y: surfaceY + 66), count: 6, color: Palette.cream)
            shake(amount: 3)
            Haptics.tap()
            SoundFX.shared.play(.good)
            return
        }
        goods += 1
        score += Tuning.goodPoints
        beltSpeed = min(maxSpeed, beltSpeed + Tuning.goodBoost)
        popup(L("İYİ", "GOOD"), color: Palette.cream, size: 38, at: CGPoint(x: 130, y: surfaceY + 160))
        popup("+\(Tuning.goodPoints)", color: Palette.green, size: 24, at: CGPoint(x: 130, y: surfaceY + 122), rotation: -0.1, shadowColor: nil)
        shake(amount: 4)
        Haptics.good()

        if nail.kind == .spring && !nail.bounced {
            SoundFX.shared.play(.good)
            springBack(nail)
            return
        }
        let done = nail.hit(1)
        sparks(at: CGPoint(x: hammerX, y: surfaceY + (done ? 10 : 36)), count: 5, color: Palette.cream)
        SoundFX.shared.play(done ? .drive : .good)
        if done { finish(nail) }
    }

    /// Çivi tamamen gömüldü: para, bonuslar ve seviye ilerlemesi.
    private func finish(_ nail: NailNode) {
        nail.resolved = true
        onEvent?(.driven(nail.kind))
        if assistLeft > 0 {
            assistLeft -= 1
            if assistLeft == 0 { hintLabel?.run(.fadeOut(withDuration: 0.4)) }
        }
        runCoins += 1 + hammerVariant.coinBonus
        switch nail.kind {
        case .gold:
            runCoins += Tuning.goldCoins
            popup(L("+\(Tuning.goldCoins + 1) PARA", "+\(Tuning.goldCoins + 1) COINS"), color: Palette.yellow, size: 22,
                  at: CGPoint(x: 270, y: surfaceY + 180), rotation: 0.08, shadowColor: nil)
            SoundFX.shared.play(.coin)
        case .hard:
            runCoins += Tuning.hardCoins
            score += Tuning.hardBonus
            popup(L("ZORLU +\(Tuning.hardBonus)", "TOUGH +\(Tuning.hardBonus)"), color: Palette.orange, size: 26,
                  at: CGPoint(x: 270, y: surfaceY + 180), rotation: 0.08, shadowColor: nil)
            if case .hard = level?.goal { addProgress(1) }
        case .plate:
            score += Tuning.plateBonus
            popup(L("LEVHA +\(Tuning.plateBonus)", "PLATE +\(Tuning.plateBonus)"), color: Palette.cream, size: 24,
                  at: CGPoint(x: 270, y: surfaceY + 180), rotation: 0.08, shadowColor: nil)
        default:
            break
        }
        if case .drive = level?.goal { addProgress(1) }
    }

    /// Yaylı çivi: yarıya girer, sonra geri zıplayıp tekrar çekicin altına gelir.
    private func springBack(_ nail: NailNode) {
        _ = nail.hit(1)
        nail.bounced = true
        sparks(at: CGPoint(x: hammerX, y: surfaceY + 36), count: 5, color: Palette.green)
        popup(L("BOİNG!", "BOING!"), color: Palette.green, size: 26, at: CGPoint(x: 270, y: surfaceY + 170), rotation: 0.1, shadowColor: nil)
        let jump = SKAction.group([
            .moveBy(x: Tuning.springBack, y: 0, duration: 0.28),
            .sequence([.moveBy(x: 0, y: 46, duration: 0.14), .moveBy(x: 0, y: -46, duration: 0.14)])
        ])
        jump.timingMode = .easeOut
        nail.run(jump)
    }

    /// Bomba: patlar, kendisini ve yanındaki iki çiviyi gömer.
    private func explode(_ bomb: NailNode) {
        bomb.setDriven()
        finish(bomb)
        let victims = nails
            .filter { !$0.resolved && !$0.kind.isBubble && $0.kind != .red && $0 !== bomb }
            .filter { worldX($0) > hammerX - 40 && worldX($0) < hammerX + Tuning.bombRadius }
            .sorted { worldX($0) < worldX($1) }
            .prefix(2)
        for v in victims {
            v.setDriven()
            finish(v)
            streak += 1
            bestStreak = max(bestStreak, streak)
            onEvent?(.streak(streak))
        }
        score += Tuning.bombBonus
        popup(L("BUM! +\(Tuning.bombBonus)", "BOOM! +\(Tuning.bombBonus)"), color: Palette.orange, size: 40, at: CGPoint(x: 250, y: surfaceY + 200), rotation: 0.1)
        let ring = SKShapeNode(circleOfRadius: 30)
        ring.position = CGPoint(x: hammerX, y: surfaceY + 20)
        ring.strokeColor = Palette.orange
        ring.fillColor = Palette.yellow.withAlphaComponent(0.4)
        ring.lineWidth = 6
        ring.zPosition = 25
        world.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 6, duration: 0.35), .fadeOut(withDuration: 0.35)]), .removeFromParent()]))
        sparks(at: CGPoint(x: hammerX, y: surfaceY + 20), count: 20, color: Palette.orange)
        flash(Palette.yellow)
        shake(amount: 14)
    }

    /// Kenardan vuruş: çivi eğri girer ve artık vurulamaz. Az puan, can gitmez, seri bozulur.
    /// Bomba çivi kenardan vurulursa can gider.
    private func bend(_ nail: NailNode) {
        streak = 0
        multiplier = 1
        nail.resolved = true
        nail.bend()
        wobble(nail)
        if nail.kind == .bomb {
            redHits += 1
            popup(L("BOMBA!", "BOMB!"), color: Palette.red, size: 38, at: CGPoint(x: 130, y: surfaceY + 160), shadowColor: Palette.redShadow)
            loseLife(.bomb)
            return
        }
        weaks += 1
        score += Tuning.weakPoints
        popup(L("EĞRİ", "BENT"), color: Palette.orange, size: 34, at: CGPoint(x: 130, y: surfaceY + 160))
        popup("+\(Tuning.weakPoints)", color: Palette.muted, size: 22, at: CGPoint(x: 130, y: surfaceY + 122), rotation: -0.1, shadowColor: nil)
        shake(amount: 5)
        Haptics.good()
        SoundFX.shared.play(.drive)
    }

    /// Kırmızı çiviye vuruldu: bir can gider.
    private func hitRed(_ nail: NailNode) {
        redHits += 1
        nail.resolved = true
        nail.bend()
        wobble(nail)
        popup(L("KIRMIZI!", "RED!"), color: Palette.red, size: 38, at: CGPoint(x: 130, y: surfaceY + 160), shadowColor: Palette.redShadow)
        loseLife(.red)
    }

    /// Güçlendirici baloncuğu toplandı.
    private func collect(_ nail: NailNode, _ p: Powerup) {
        nail.resolved = true
        nail.removeAction(forKey: "float")
        nail.run(.sequence([
            .group([.moveBy(x: 0, y: 120, duration: 0.35), .fadeOut(withDuration: 0.35), .scale(to: 1.4, duration: 0.35)]),
            .removeFromParent()
        ]))
        popup("+1 \(p.title.uppercased(with: Locale(identifier: Lang.localeID)))", color: p.uiColor, size: 26,
              at: CGPoint(x: 195, y: surfaceY + 200), rotation: 0, shadowColor: nil)
        sparks(at: CGPoint(x: hammerX, y: surfaceY + 30), count: 8, color: p.uiColor)
        Haptics.success()
        SoundFX.shared.play(.coin)
        onPowerupCollected?(p)
    }

    /// Boşa vuruş: can gitmez ama seri bozulur.
    private func hitWood() {
        woodHits += 1
        streak = 0
        multiplier = 1
        popup(L("BOŞ", "MISS"), color: Palette.muted, size: 26, at: CGPoint(x: 130, y: surfaceY + 150), shadowColor: nil)
        shake(amount: 3)
        Haptics.tap()
        SoundFX.shared.play(.good)
    }

    private func loseLife(_ reason: LossReason) {
        guard lives > 0 else { return }
        lives -= 1
        lastLoss = reason
        streak = 0
        multiplier = 1
        beltSpeed = max(startSpeed, beltSpeed - Tuning.lossSlowdown)
        flash(Palette.red)
        shake(amount: 11)
        Haptics.miss()
        SoundFX.shared.play(.miss)

        if lives <= 0 {
            running = false
            run(.sequence([
                .wait(forDuration: 0.8),
                .run { [weak self] in self?.isOver = true }
            ]), withKey: "gameOver")
        }
    }

    // MARK: - Seviye hedefi

    private func addProgress(_ amount: Int) {
        guard let level, !isComplete, running else { return }
        progress = min(level.goal.count, progress + amount)
        if progress >= level.goal.count {
            running = false
            zoneTime = 0
            slowTime = 0
            updateBoostDisplay()
            popup(L("TAMAM!", "DONE!"), color: Palette.green, size: 56, at: CGPoint(x: 195, y: surfaceY + 230), rotation: 0, shadowColor: Palette.greenShadow)
            Haptics.success()
            SoundFX.shared.play(.coin)
            run(.sequence([
                .wait(forDuration: 1.0),
                .run { [weak self] in self?.isComplete = true }
            ]), withKey: "complete")
        }
    }

    // MARK: - Tempo dalgaları

    private func updateTempo(_ dt: CGFloat) {
        // Hedef tempoya yumuşakça yaklaş (birkaç saniyede)
        tempo += (tempoTarget - tempo) * min(1, dt * Tuning.tempoEase)

        guard tempoEnabled else { return }
        tempoTimer -= TimeInterval(dt)
        guard tempoTimer <= 0 else { return }
        tempoTimer = TimeInterval.random(in: Tuning.tempoDuration)

        let options = Tuning.tempos.filter { abs($0 - tempoTarget) > 0.01 }
        guard let next = options.randomElement() else { return }
        if next > tempoTarget + 0.1 {
            popup(L("HIZLANIYOR!", "SPEEDING UP!"), color: Palette.orange, size: 28, at: CGPoint(x: 195, y: bottomLabelY), rotation: 0, shadowColor: Palette.brownShadow)
        } else if next < tempoTarget - 0.1 {
            popup(L("YAVAŞLIYOR", "SLOWING DOWN"), color: Palette.green, size: 26, at: CGPoint(x: 195, y: bottomLabelY), rotation: 0, shadowColor: nil)
        }
        tempoTarget = next
    }

    private func startIdle() {
        guard let hammer else { return }
        hammer.removeAction(forKey: "idle")
        let a = SKAction.rotate(toAngle: restAngle + 0.06, duration: 0.6, shortestUnitArc: true)
        a.timingMode = .easeInEaseOut
        let b = SKAction.rotate(toAngle: restAngle - 0.03, duration: 0.6, shortestUnitArc: true)
        b.timingMode = .easeInEaseOut
        hammer.run(.repeatForever(.sequence([a, b])), withKey: "idle")
    }

    // MARK: - Efektler

    private func wobble(_ nail: NailNode) {
        nail.run(.sequence([
            .rotate(byAngle: -0.12, duration: 0.05),
            .rotate(byAngle: 0.2, duration: 0.07),
            .rotate(byAngle: -0.08, duration: 0.06)
        ]))
    }

    private func popup(_ text: String, color: UIColor, size: CGFloat, at pos: CGPoint,
                       rotation: CGFloat = -0.14, shadowColor: UIColor? = Palette.brownShadow) {
        let node = SKNode()
        node.position = pos
        node.zRotation = rotation
        node.zPosition = 50

        if let shadowColor {
            let back = SKLabelNode(fontNamed: TKFont.displayName)
            back.text = text
            back.fontSize = size
            back.fontColor = shadowColor
            back.verticalAlignmentMode = .center
            back.position = CGPoint(x: 0, y: -4)
            node.addChild(back)
        }
        let label = SKLabelNode(fontNamed: TKFont.displayName)
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        node.addChild(label)

        addChild(node)
        node.setScale(0.4)
        node.run(.sequence([
            .scale(to: 1.15, duration: 0.08),
            .scale(to: 1.0, duration: 0.06),
            .wait(forDuration: 0.3),
            .group([.fadeOut(withDuration: 0.25), .moveBy(x: 0, y: 30, duration: 0.25)]),
            .removeFromParent()
        ]))
    }

    private func sparks(at point: CGPoint, count: Int, color: UIColor) {
        for _ in 0..<count {
            let s = SKShapeNode(rectOf: CGSize(width: 5, height: 14), cornerRadius: 2.5)
            s.fillColor = color
            s.strokeColor = .clear
            s.position = point
            s.zPosition = 20
            let angle = CGFloat.random(in: (0.12 * .pi)...(0.88 * .pi))
            let dist = CGFloat.random(in: 45...95)
            s.zRotation = angle - .pi / 2
            world.addChild(s)
            let fly = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.24)
            fly.timingMode = .easeOut
            s.run(.sequence([
                .group([fly, .fadeOut(withDuration: 0.24), .scale(to: 0.4, duration: 0.24)]),
                .removeFromParent()
            ]))
        }
    }

    private func shake(amount: CGFloat) {
        world.removeAction(forKey: "shake")
        world.position = .zero
        var steps: [SKAction] = []
        var a = amount
        for _ in 0..<4 {
            steps.append(.move(to: CGPoint(x: CGFloat.random(in: -a...a), y: CGFloat.random(in: -a...a)), duration: 0.025))
            a *= 0.6
        }
        steps.append(.move(to: .zero, duration: 0.03))
        world.run(.sequence(steps), withKey: "shake")
    }

    private func flash(_ color: UIColor) {
        let f = SKSpriteNode(color: color, size: CGSize(width: size.width * 2, height: size.height * 2))
        f.position = CGPoint(x: size.width / 2, y: size.height / 2)
        f.alpha = 0
        f.zPosition = 100
        addChild(f)
        f.run(.sequence([.fadeAlpha(to: 0.3, duration: 0.05), .fadeOut(withDuration: 0.35), .removeFromParent()]))
    }
}

// MARK: - Çivi türleri

enum NailKind: Equatable {
    case normal, gold, hard, red, plate, spring, ice, bomb
    /// Bantta yüzen güçlendirici baloncuğu (çivi değil)
    case bubble(Powerup)

    var isBubble: Bool {
        if case .bubble = self { return true }
        return false
    }

    var tint: NailTint {
        switch self {
        case .normal, .bubble: return .steel
        case .gold: return .gold
        case .hard: return .hard
        case .red: return .red
        case .plate: return .plate
        case .spring: return .spring
        case .ice: return .ice
        case .bomb: return .bomb
        }
    }

    /// Tam gömülmek için gereken derinlik. Mükemmel vuruş 2, iyi vuruş 1 birim.
    var depthNeeded: Int {
        self == .hard ? 4 : 2
    }
}

// MARK: - Çivi düğümü

final class NailNode: SKSpriteNode {
    let kind: NailKind
    private(set) var state: NailState = .up
    private(set) var depth = 0
    /// Çakıldı, eğildi ya da geçti: artık vurulamaz.
    var resolved = false
    /// Yaylı çivi bir kez geri zıpladı mı
    var bounced = false
    /// Buz çivisinin kayma katsayısı (negatif: hızlanır, pozitif: yavaşlar)
    var slip: CGFloat = 0
    var glinted = false
    private let side: CGFloat

    init(kind: NailKind, size: CGFloat) {
        self.kind = kind
        self.side = size
        let tex: SKTexture
        if case .bubble(let p) = kind {
            tex = SKTexture(image: PowerupArt.bubble(p, size: size * 0.72))
        } else {
            tex = SKTexture(image: NailArt.image(.up, kind.tint, size: size))
        }
        let s: CGFloat = kind.isBubble ? size * 0.72 : size
        super.init(texture: tex, color: .clear, size: CGSize(width: s, height: s))
        anchorPoint = CGPoint(x: 0.5, y: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    /// Çiviyi `amount` birim çakar. Tamamen gömüldüyse true döner.
    func hit(_ amount: Int) -> Bool {
        depth = min(kind.depthNeeded, depth + amount)
        let ratio = CGFloat(depth) / CGFloat(kind.depthNeeded)
        if ratio >= 1 {
            set(.driven)
            return true
        }
        if ratio >= 0.5 {
            set(.half)
        }
        // Zorlu çivide ilk "iyi" vuruş çiviyi biraz oturtur: küçük bir sarsıntı yeter.
        run(.sequence([.moveBy(x: 0, y: -2, duration: 0.03), .moveBy(x: 0, y: 2, duration: 0.05)]))
        return false
    }

    func setDriven() {
        depth = kind.depthNeeded
        set(.driven)
    }

    func bend() {
        set(.bent)
    }

    private func set(_ newState: NailState) {
        guard !kind.isBubble else { return }
        state = newState
        texture = SKTexture(image: NailArt.image(newState, kind.tint, size: side))
    }
}
