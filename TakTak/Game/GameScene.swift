import SpriteKit
import UIKit

/// Oyunun kalbi.
///
/// Döngü: Göstergedeki ibre sağa sola gider. Oyuncu ekrana dokunur, çekiç iner.
/// - İbre yeşil (mükemmel) bölgedeyse çivi tek vuruşta gömülür; seri ve çarpan artar.
/// - Kahverengi (iyi) bölgedeyse çivi yarıya girer; ikinci bir vuruş gerekir, seri sıfırlanır.
/// - Dışındaysa çivi eğilir ve oyun biter.
/// Her çividen sonra bant bir adım sola kayar; ibre hızlanır, bölgeler daralır.
final class GameScene: SKScene, ObservableObject {

    // MARK: - SwiftUI'ye yayınlanan durum

    @Published private(set) var score = 0
    @Published private(set) var multiplier = 1
    @Published private(set) var runCoins = 0
    @Published private(set) var isOver = false
    @Published private(set) var hasContinued = false

    // MARK: - Ayarlanabilir oyun dengesi

    private enum Tuning {
        static let baseSpeed: CGFloat = 0.85        // ibre hızı (gösterge genişliği / saniye)
        static let speedPerPoint: CGFloat = 0.035
        static let maxSpeed: CGFloat = 2.4
        static let basePerfect: CGFloat = 0.13      // mükemmel bölge genişliği (oran)
        static let minPerfect: CGFloat = 0.06
        static let perfectShrink: CGFloat = 0.0015
        static let baseGoodHalf: CGFloat = 0.20     // iyi bölgenin yarı genişliği
        static let minGoodHalf: CGFloat = 0.12
        static let goodShrink: CGFloat = 0.002
        static let goldChance: Double = 0.12
        static let goldBonus = 5
    }

    // MARK: - Yerleşim (390x844 tasarım ölçüsü, SpriteKit'te y yukarı)

    private let surfaceY: CGFloat = 240           // tahtanın üst yüzeyi
    private let hammerX: CGFloat = 195            // vuruş noktası
    private let spacing: CGFloat = 110            // çiviler arası mesafe
    private let nailSize: CGFloat = 80
    private let hammerSize: CGFloat = 260
    private let restAngle: CGFloat = 0.47         // bekleme açısı (radyan)
    private let meterWidth: CGFloat = 326
    private let meterY: CGFloat = 101

    // MARK: - Düğümler

    private let world = SKNode()
    private let track = SKNode()
    private var hammer: SKSpriteNode?
    private var tiles: [Int: SKSpriteNode] = [:]
    private var nails: [Int: NailNode] = [:]
    private var current = 0

    private let meter = SKNode()
    private var goodZone: SKSpriteNode?
    private var perfectZone: SKSpriteNode?
    private var indicator: SKShapeNode?
    private var hintLabel: SKLabelNode?

    // MARK: - Durum

    private enum Phase { case ready, swinging, advancing, dead }
    private enum HitResult { case perfect, good, miss }

    private var phase: Phase = .ready
    private var hammerVariant: HammerVariant = .klasik
    private var built = false
    private var needle: CGFloat = 0          // ibre konumu 0...1
    private var direction: CGFloat = 1
    private var zoneCenter: CGFloat = 0.5
    private var perfectWidth: CGFloat = Tuning.basePerfect
    private var goodHalf: CGFloat = Tuning.baseGoodHalf
    private var lastTime: TimeInterval = 0
    private var streak = 0
    private var started = false

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

        buildMeter()
    }

    private func hammerTexture() -> SKTexture {
        SKTexture(image: HammerArt.image(hammerVariant, size: hammerSize, angle: 0, shadow: false))
    }

    private func buildMeter() {
        meter.position = CGPoint(x: 195, y: meterY)
        meter.zPosition = 30
        addChild(meter)

        let bar = SKShapeNode(rectOf: CGSize(width: meterWidth, height: 22), cornerRadius: 11)
        bar.fillColor = Palette.panel
        bar.strokeColor = .clear
        meter.addChild(bar)

        let good = SKSpriteNode(color: Palette.meterGood, size: CGSize(width: 10, height: 22))
        good.zPosition = 1
        meter.addChild(good)
        goodZone = good

        let perfect = SKSpriteNode(color: Palette.green, size: CGSize(width: 10, height: 22))
        perfect.zPosition = 2
        meter.addChild(perfect)
        perfectZone = perfect

        let ind = SKShapeNode(rectOf: CGSize(width: 8, height: 38), cornerRadius: 4)
        ind.fillColor = Palette.cream
        ind.strokeColor = Palette.bg
        ind.lineWidth = 3
        ind.zPosition = 3
        meter.addChild(ind)
        indicator = ind

        let hint = SKLabelNode(fontNamed: TKFont.extraBoldName)
        hint.text = "Ekranın herhangi bir yerine dokun"
        hint.fontSize = 15
        hint.fontColor = Palette.muted
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -42)
        meter.addChild(hint)
        hintLabel = hint
    }

    // MARK: - Dışarıdan çağrılanlar

    func restart() {
        resetRun()
    }

    /// "Devam et": eğilen çiviyi yenisiyle değiştirir. Oyun başına bir kez.
    func revive() {
        guard isOver, !hasContinued else { return }
        hasContinued = true
        if let old = nails[current] {
            old.removeAllActions()
            old.removeFromParent()
        }
        let fresh = makeNail(index: current, state: .up, tint: .steel)
        nails[current] = fresh
        streak = 0
        multiplier = 1
        newZone()
        hammer?.removeAllActions()
        hammer?.zRotation = restAngle
        startIdle()
        isOver = false
        phase = .ready
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
        nails.values.forEach { $0.removeFromParent() }
        nails.removeAll()
        tiles.values.forEach { $0.removeFromParent() }
        tiles.removeAll()
        track.removeAllActions()
        track.position = .zero
        world.removeAllActions()
        world.position = .zero

        current = 0
        score = 0
        multiplier = 1
        runCoins = 0
        streak = 0
        isOver = false
        hasContinued = false
        phase = .ready
        needle = 0
        direction = 1
        lastTime = 0
        started = false

        hintLabel?.alpha = 1
        hammer?.removeAllActions()
        hammer?.texture = hammerTexture()
        hammer?.zRotation = restAngle
        startIdle()

        refreshTrack()
        newZone()
    }

    // MARK: - Bant ve çiviler

    private func refreshTrack() {
        // Kalaslar: görünen aralığı kapsayan karoları oluştur, dışarıda kalanları sil.
        let tx = track.position.x
        let first = Int(floor((-80 - tx) / BeltArt.unitWidth))
        let last = Int(floor((470 - tx) / BeltArt.unitWidth))
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

        // Çiviler: geride çakılmış olanlar, önde bekleyenler.
        for i in (current - 3)...(current + 3) where nails[i] == nil {
            let state: NailState = i < 0 ? .driven : .up
            let gold = i >= 3 && Double.random(in: 0..<1) < Tuning.goldChance
            nails[i] = makeNail(index: i, state: state, tint: gold ? .gold : .steel)
        }
        for (i, nail) in nails where i < current - 4 {
            nail.removeFromParent()
            nails[i] = nil
        }
    }

    private func makeNail(index: Int, state: NailState, tint: NailTint) -> NailNode {
        let n = NailNode(state: state, tint: tint, size: nailSize)
        n.position = CGPoint(x: hammerX + CGFloat(index) * spacing, y: surfaceY)
        n.zPosition = 3
        track.addChild(n)
        return n
    }

    private func newZone() {
        let s = CGFloat(score)
        perfectWidth = max(Tuning.minPerfect, Tuning.basePerfect - Tuning.perfectShrink * s)
        goodHalf = max(Tuning.minGoodHalf, Tuning.baseGoodHalf - Tuning.goodShrink * s)
        let margin = goodHalf + 0.05
        zoneCenter = CGFloat.random(in: margin...(1 - margin))

        let x = (zoneCenter - 0.5) * meterWidth
        goodZone?.size.width = goodHalf * 2 * meterWidth
        goodZone?.position.x = x
        perfectZone?.size.width = perfectWidth * meterWidth
        perfectZone?.position.x = x

        perfectZone?.removeAllActions()
        perfectZone?.setScale(1)
        perfectZone?.run(.sequence([.scaleY(to: 1.35, duration: 0.06), .scaleY(to: 1, duration: 0.1)]))
    }

    // MARK: - Döngü

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, 1.0 / 30.0)
        lastTime = currentTime
        guard !isOver, phase != .dead else { return }

        let speed = min(Tuning.maxSpeed, Tuning.baseSpeed + Tuning.speedPerPoint * CGFloat(score))
        needle += direction * speed * CGFloat(dt)
        if needle > 1 { needle = 2 - needle; direction = -1 }
        if needle < 0 { needle = -needle; direction = 1 }
        indicator?.position.x = (needle - 0.5) * meterWidth
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tap()
    }

    // MARK: - Vuruş

    private func tap() {
        guard phase == .ready, !isOver, let hammer, let nail = nails[current] else { return }

        if !started {
            started = true
            hintLabel?.run(.fadeOut(withDuration: 0.3))
        }

        phase = .swinging
        let result = evaluate()
        let strike: CGFloat = nail.state == .half ? 103 * .pi / 180 : .pi / 2

        hammer.removeAction(forKey: "idle")
        let down = SKAction.rotate(toAngle: strike, duration: 0.06, shortestUnitArc: false)
        down.timingMode = .easeIn
        let up = SKAction.rotate(toAngle: restAngle, duration: 0.18, shortestUnitArc: false)
        up.timingMode = .easeOut

        hammer.run(.sequence([
            down,
            .run { [weak self] in self?.impact(result) },
            .wait(forDuration: 0.05),
            up,
            .run { [weak self] in
                guard let self else { return }
                if self.phase == .swinging { self.phase = .ready }
                self.startIdle()
            }
        ]))
    }

    private func evaluate() -> HitResult {
        let d = abs(needle - zoneCenter)
        if d <= perfectWidth / 2 + 0.008 { return .perfect }
        if d <= goodHalf { return .good }
        return .miss
    }

    private func impact(_ result: HitResult) {
        guard let nail = nails[current] else { return }
        let headPoint = CGPoint(x: hammerX, y: surfaceY + 10)

        switch result {
        case .perfect:
            streak += 1
            multiplier = min(5, 1 + streak / 3)
            let gained = multiplier
            score += gained
            nail.set(.driven)
            payCoins(for: nail)
            popup("MÜKEMMEL!", color: Palette.yellow, size: 46, at: CGPoint(x: 140, y: 410))
            popup("+\(gained)", color: Palette.green, size: 26, at: CGPoint(x: 140, y: 366), rotation: -0.1, shadow: false)
            sparks(at: headPoint, count: 12, color: Palette.yellow)
            shake(amount: 9)
            Haptics.perfect()
            SoundFX.shared.play(.perfect)
            advance()

        case .good:
            streak = 0
            multiplier = 1
            if nail.state == .up {
                nail.set(.half)
                popup("İYİ", color: Palette.cream, size: 38, at: CGPoint(x: 130, y: 400))
                sparks(at: CGPoint(x: hammerX, y: surfaceY + 36), count: 5, color: Palette.cream)
                shake(amount: 4)
                Haptics.good()
                SoundFX.shared.play(.good)
                newZone()
            } else {
                nail.set(.driven)
                score += 1
                payCoins(for: nail)
                popup("+1", color: Palette.green, size: 26, at: CGPoint(x: 130, y: 380), shadow: false)
                sparks(at: headPoint, count: 6, color: Palette.cream)
                shake(amount: 5)
                Haptics.good()
                SoundFX.shared.play(.drive)
                advance()
            }

        case .miss:
            streak = 0
            multiplier = 1
            phase = .dead
            nail.set(.bent)
            nail.run(.sequence([
                .rotate(byAngle: -0.12, duration: 0.05),
                .rotate(byAngle: 0.2, duration: 0.07),
                .rotate(byAngle: -0.08, duration: 0.06)
            ]))
            flash(Palette.red)
            shake(amount: 12)
            Haptics.miss()
            SoundFX.shared.play(.miss)
            run(.sequence([
                .wait(forDuration: 0.75),
                .run { [weak self] in self?.isOver = true }
            ]), withKey: "gameOver")
        }
    }

    private func payCoins(for nail: NailNode) {
        if nail.tint == .gold {
            runCoins += 1 + Tuning.goldBonus
            popup("+\(Tuning.goldBonus + 1) PARA", color: Palette.yellow, size: 22, at: CGPoint(x: 270, y: 420), rotation: 0.08, shadow: false)
            SoundFX.shared.play(.coin)
        } else {
            runCoins += 1
        }
    }

    private func advance() {
        phase = .advancing
        let move = SKAction.moveBy(x: -spacing, y: 0, duration: 0.2)
        move.timingMode = .easeInEaseOut
        track.run(.sequence([
            .wait(forDuration: 0.1),
            move,
            .run { [weak self] in
                guard let self else { return }
                self.current += 1
                self.refreshTrack()
                self.newZone()
                if self.phase == .advancing { self.phase = .ready }
            }
        ]))
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
                       rotation: CGFloat = -0.14, shadow: Bool = true) {
        let node = SKNode()
        node.position = pos
        node.zRotation = rotation
        node.zPosition = 50

        if shadow {
            let back = SKLabelNode(fontNamed: TKFont.displayName)
            back.text = text
            back.fontSize = size
            back.fontColor = Palette.brownShadow
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
            .wait(forDuration: 0.35),
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

// MARK: - Çivi düğümü

final class NailNode: SKSpriteNode {
    private(set) var state: NailState
    let tint: NailTint
    private let side: CGFloat

    init(state: NailState, tint: NailTint, size: CGFloat) {
        self.state = state
        self.tint = tint
        self.side = size
        let tex = SKTexture(image: NailArt.image(state, tint, size: size))
        super.init(texture: tex, color: .clear, size: CGSize(width: size, height: size))
        anchorPoint = CGPoint(x: 0.5, y: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    func set(_ newState: NailState) {
        state = newState
        texture = SKTexture(image: NailArt.image(newState, tint, size: side))
    }
}
