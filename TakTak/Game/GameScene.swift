import SpriteKit
import UIKit

/// Oyunun kalbi.
///
/// Bant sürekli sola akar, üstündeki çiviler çekicin altından geçer.
/// Oyuncu, çivi sarı okun üstüne geldiği anda dokunur:
/// - Tam ortadaysa **mükemmel**: çivi derin girer, seri ve çarpan artar.
/// - Biraz kaymışsa **iyi**: çivi yarıya girer, seri sıfırlanır.
/// - Çok kaymışsa çivi **eğilir**: bir can gider.
/// - Hiç vurulmadan geçen ya da yarım kalan çivi **kaçar**: bir can gider.
/// Bant yavaş başlar; iyi vuruşlarla hızlanır, can kaybında biraz yavaşlar.
final class GameScene: SKScene, ObservableObject {

    enum LossReason { case bent, escaped }

    static let maxLives = 3

    // MARK: - SwiftUI'ye yayınlanan durum

    @Published private(set) var score = 0
    @Published private(set) var multiplier = 1
    @Published private(set) var runCoins = 0
    @Published private(set) var lives = GameScene.maxLives
    @Published private(set) var isOver = false
    @Published private(set) var hasContinued = false
    @Published private(set) var lastLoss: LossReason = .bent

    // MARK: - Oyun dengesi

    private enum Tuning {
        // Bant hızı (pt/sn)
        static let startSpeed: CGFloat = 70
        static let maxSpeed: CGFloat = 300
        static let perfectBoost: CGFloat = 3.5
        static let goodBoost: CGFloat = 1.5
        static let lossSlowdown: CGFloat = 22

        // Vuruş anında çivinin çekiç eksenine uzaklığı (pt)
        static let perfectWindow: CGFloat = 10
        static let goodWindow: CGFloat = 26
        static let bendWindow: CGFloat = 40

        // Çivi aralığı
        static let minReaction: CGFloat = 0.55      // iki çivi arası en az süre (sn)
        static let minGap: CGFloat = 70
        static let extraGap: ClosedRange<CGFloat> = 0...130
        static let pairAfter = 25                   // bu kadar çividen sonra çift çiviler gelebilir
        static let pairChance = 0.12
        static let pairReaction: CGFloat = 0.35

        // Çivi türleri
        static let goldChance = 0.08
        static let hardAfter = 12
        static let hardChanceBase = 0.15
        static let hardChanceMax = 0.28

        // Puan ve para
        static let perfectPoints = 3
        static let goodPoints = 1
        static let hardBonus = 5
        static let streakStep = 5                   // her 5 mükemmel vuruşta çarpan +1
        static let maxMultiplier = 5
        static let goldCoins = 5
        static let hardCoins = 2
    }

    // MARK: - Yerleşim (genişlik 390, SpriteKit'te y yukarı)

    private let surfaceY: CGFloat = 240
    private let hammerX: CGFloat = 195
    private let nailSize: CGFloat = 80
    private let hammerSize: CGFloat = 260
    private let restAngle: CGFloat = 0.47

    // MARK: - Düğümler

    private let world = SKNode()
    private let track = SKNode()
    private var hammer: SKSpriteNode?
    private var tiles: [Int: SKSpriteNode] = [:]
    private var nails: [NailNode] = []
    private var hintLabel: SKLabelNode?

    // MARK: - Durum

    private var hammerVariant: HammerVariant = .klasik
    private var built = false
    private var running = false
    private var striking = false
    private var started = false
    private var beltSpeed: CGFloat = Tuning.startSpeed
    private var nextSpawnX: CGFloat = 0
    private var spawned = 0
    private var streak = 0
    private var lastTime: TimeInterval = 0

    convenience init(hammer: HammerVariant) {
        self.init(size: CGSize(width: 390, height: 844))
        hammerVariant = hammer
        scaleMode = .aspectFill
        backgroundColor = Palette.bg
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
                                size: CGSize(width: Tuning.goodWindow * 2, height: 120))
        good.anchorPoint = CGPoint(x: 0.5, y: 0)
        good.position = CGPoint(x: hammerX, y: surfaceY)
        good.zPosition = 2.5
        world.addChild(good)
        let perfect = SKSpriteNode(color: Palette.green.withAlphaComponent(0.12),
                                   size: CGSize(width: Tuning.perfectWindow * 2, height: 120))
        perfect.anchorPoint = CGPoint(x: 0.5, y: 0)
        perfect.position = CGPoint(x: hammerX, y: surfaceY)
        perfect.zPosition = 2.6
        world.addChild(perfect)

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
        hint.text = "Çivi sarı okun üstüne gelince dokun"
        hint.fontSize = 15
        hint.fontColor = Palette.muted
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 195, y: 92)
        hint.zPosition = 30
        addChild(hint)
        hintLabel = hint
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

    // MARK: - Tur sıfırlama

    private func resetRun() {
        removeAction(forKey: "gameOver")
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
        lives = GameScene.maxLives
        isOver = false
        hasContinued = false
        lastLoss = .bent
        beltSpeed = Tuning.startSpeed
        spawned = 0
        streak = 0
        lastTime = 0
        started = false
        striking = false
        running = true

        hintLabel?.removeAllActions()
        hintLabel?.alpha = 1
        hammer?.removeAllActions()
        hammer?.texture = hammerTexture()
        hammer?.zRotation = restAngle
        startIdle()

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

        track.position.x -= beltSpeed * dt
        refreshTiles()
        spawnIfNeeded()
        checkEscapes()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tap()
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
        let r = Double.random(in: 0..<1)
        if spawned >= Tuning.hardAfter {
            let hardChance = min(Tuning.hardChanceMax, Tuning.hardChanceBase + Double(spawned) * 0.002)
            if r < hardChance { return .hard }
            if r < hardChance + Tuning.goldChance { return .gold }
        } else if spawned >= 3, r < Tuning.goldChance {
            return .gold
        }
        return .normal
    }

    private func nextGap() -> CGFloat {
        if spawned > Tuning.pairAfter, Double.random(in: 0..<1) < Tuning.pairChance {
            return max(60, beltSpeed * Tuning.pairReaction)
        }
        let minGap = max(Tuning.minGap, beltSpeed * Tuning.minReaction)
        return minGap + CGFloat.random(in: Tuning.extraGap)
    }

    @discardableResult
    private func makeNail(kind: NailKind, at x: CGFloat) -> NailNode {
        let n = NailNode(kind: kind, size: nailSize)
        n.position = CGPoint(x: x, y: surfaceY)
        n.zPosition = 3
        track.addChild(n)
        nails.append(n)
        return n
    }

    private func checkEscapes() {
        for nail in nails where !nail.resolved && worldX(nail) < hammerX - Tuning.bendWindow {
            nail.resolved = true
            popup("KAÇTI!", color: Palette.red, size: 34, at: CGPoint(x: 90, y: 400), shadowColor: Palette.redShadow)
            loseLife(.escaped)
            if isOver || lives <= 0 { break }
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

    // MARK: - Vuruş

    private func tap() {
        guard running, !isOver, !striking, let hammer else { return }

        if !started {
            started = true
            hintLabel?.run(.sequence([.wait(forDuration: 1.5), .fadeOut(withDuration: 0.4)]))
        }

        striking = true
        let aim = target(within: Tuning.bendWindow + 30)
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
        guard let nail = target(within: Tuning.bendWindow) else {
            hitWood()
            return
        }
        let dx = abs(worldX(nail) - hammerX)
        if dx <= Tuning.perfectWindow {
            perfectHit(nail)
        } else if dx <= Tuning.goodWindow {
            goodHit(nail)
        } else {
            bend(nail)
        }
    }

    private func perfectHit(_ nail: NailNode) {
        streak += 1
        multiplier = min(Tuning.maxMultiplier, 1 + streak / Tuning.streakStep)
        let points = Tuning.perfectPoints * multiplier
        score += points
        beltSpeed = min(Tuning.maxSpeed, beltSpeed + Tuning.perfectBoost)

        let done = nail.hit(2)
        popup("MÜKEMMEL!", color: Palette.yellow, size: 46, at: CGPoint(x: 140, y: 410))
        popup("+\(points)", color: Palette.green, size: 26, at: CGPoint(x: 140, y: 366), rotation: -0.1, shadowColor: nil)
        sparks(at: CGPoint(x: hammerX, y: surfaceY + (done ? 10 : 36)), count: 12, color: Palette.yellow)
        shake(amount: 8)
        Haptics.perfect()
        SoundFX.shared.play(.perfect)
        if done { finish(nail) }
    }

    private func goodHit(_ nail: NailNode) {
        streak = 0
        multiplier = 1
        score += Tuning.goodPoints
        beltSpeed = min(Tuning.maxSpeed, beltSpeed + Tuning.goodBoost)

        let done = nail.hit(1)
        popup("İYİ", color: Palette.cream, size: 38, at: CGPoint(x: 130, y: 400))
        sparks(at: CGPoint(x: hammerX, y: surfaceY + (done ? 10 : 36)), count: 5, color: Palette.cream)
        shake(amount: 4)
        Haptics.good()
        SoundFX.shared.play(done ? .drive : .good)
        if done { finish(nail) }
    }

    /// Çivi tamamen gömüldü: para ve zorlu çivi bonusu.
    private func finish(_ nail: NailNode) {
        nail.resolved = true
        switch nail.kind {
        case .normal:
            runCoins += 1
        case .gold:
            runCoins += 1 + Tuning.goldCoins
            popup("+\(Tuning.goldCoins + 1) PARA", color: Palette.yellow, size: 22,
                  at: CGPoint(x: 270, y: 420), rotation: 0.08, shadowColor: nil)
            SoundFX.shared.play(.coin)
        case .hard:
            runCoins += 1 + Tuning.hardCoins
            score += Tuning.hardBonus
            popup("ZORLU +\(Tuning.hardBonus)", color: Palette.orange, size: 26,
                  at: CGPoint(x: 270, y: 420), rotation: 0.08, shadowColor: nil)
        }
    }

    private func bend(_ nail: NailNode) {
        nail.resolved = true
        nail.bend()
        nail.run(.sequence([
            .rotate(byAngle: -0.12, duration: 0.05),
            .rotate(byAngle: 0.2, duration: 0.07),
            .rotate(byAngle: -0.08, duration: 0.06)
        ]))
        popup("EĞİLDİ!", color: Palette.red, size: 38, at: CGPoint(x: 130, y: 400), shadowColor: Palette.redShadow)
        loseLife(.bent)
    }

    /// Boşa vuruş: can gitmez ama seri bozulur.
    private func hitWood() {
        streak = 0
        multiplier = 1
        popup("BOŞ", color: Palette.muted, size: 26, at: CGPoint(x: 130, y: 390), shadowColor: nil)
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
        beltSpeed = max(Tuning.startSpeed, beltSpeed - Tuning.lossSlowdown)
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

enum NailKind {
    case normal, gold, hard

    var tint: NailTint {
        switch self {
        case .normal: return .steel
        case .gold: return .gold
        case .hard: return .hard
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
    /// Çakıldı, eğildi ya da kaçtı: artık vurulamaz.
    var resolved = false
    private let side: CGFloat

    init(kind: NailKind, size: CGFloat) {
        self.kind = kind
        self.side = size
        let tex = SKTexture(image: NailArt.image(.up, kind.tint, size: size))
        super.init(texture: tex, color: .clear, size: CGSize(width: size, height: size))
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
        state = newState
        texture = SKTexture(image: NailArt.image(newState, kind.tint, size: side))
    }
}
