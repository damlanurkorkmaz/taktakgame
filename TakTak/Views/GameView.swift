import SpriteKit
import SwiftUI

enum GameMode: Equatable {
    case level(Int)
    case endless
}

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @StateObject private var scene: GameScene
    let mode: GameMode
    /// Haritaya / menüye dön
    var onExit: () -> Void
    /// Bir seviyeyi aç (sonraki seviye ya da tekrar): tanıtım ve hedef kartları üzerinden
    var onRequestLevel: (Int) -> Void

    @State private var failResult: RunResult?
    @State private var levelResult: LevelResultInfo?
    @State private var paused = false
    @State private var banner: Quest?
    @State private var adNotReady = false
    @State private var watchingAd = false
    @State private var bannerQueue: [Quest] = []

    struct RunResult: Equatable {
        let score: Int
        let coins: Int
        let newRecord: Bool
    }

    struct LevelResultInfo: Equatable {
        let stars: Int
        let newStars: Int
        let coins: Int
        let accuracy: Double
        let perfects: Int
        let bestStreak: Int
    }

    init(mode: GameMode, hammer: HammerVariant, boosts: Set<Powerup> = [], tutorial: Bool = false,
         onExit: @escaping () -> Void, onRequestLevel: @escaping (Int) -> Void) {
        self.mode = mode
        let level: Level?
        if case .level(let n) = mode { level = Level.get(n) } else { level = nil }
        _scene = StateObject(wrappedValue: GameScene(hammer: hammer, level: level, boosts: boosts, tutorial: tutorial))
        self.onExit = onExit
        self.onRequestLevel = onRequestLevel
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, isPaused: paused, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            if scene.slowLeft > 0 {
                Rectangle()
                    .strokeBorder(Color(hex: 0x7CC8F5).opacity(0.5), lineWidth: 6)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            hud

            powerupBar
            if let banner {
                VStack {
                    QuestBanner(quest: banner)
                        .padding(.horizontal, 16)
                        .padding(.top, 70)
                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(5)
            }

            if paused {
                pauseOverlay
                    .transition(.opacity)
            }

            if let r = failResult {
                GameOverView(
                    title: scene.level == nil ? nil : L("SEVİYE BAŞARISIZ", "LEVEL FAILED"),
                    score: r.score,
                    best: store.best,
                    showBest: scene.level == nil,
                    newRecord: r.newRecord,
                    coinsEarned: r.coins,
                    canContinue: !scene.hasContinued,
                    escaped: scene.lastLoss == .escaped,
                    lossTitle: lossTitle,
                    menuTitle: scene.level == nil ? L("Ana menü", "Main menu") : L("Harita", "Map"),
                    continueWithAd: !store.noAds,
                    hammer: store.equipped,
                    onContinue: continueRun,
                    onRetry: {
                        withAnimation(.easeOut(duration: 0.2)) { failResult = nil }
                        scene.restart()
                    },
                    onMenu: onExit
                )
                .transition(.opacity)
            }

            if let info = levelResult, let level = scene.level {
                LevelCompleteView(
                    level: level,
                    stars: info.stars,
                    newStars: info.newStars,
                    coins: info.coins,
                    accuracy: info.accuracy,
                    perfects: info.perfects,
                    bestStreak: info.bestStreak,
                    onNext: { onRequestLevel(level.number + 1) },
                    onReplay: {
                        withAnimation(.easeOut(duration: 0.2)) { levelResult = nil }
                        scene.restart()
                    },
                    onMap: onExit,
                    onEndless: onExit
                )
                .transition(.opacity)
            }
        }
        .background(Color.tkBg.ignoresSafeArea())
        .onAppear {
            scene.onEvent = { event in
                let done = store.handle(event)
                if !done.isEmpty { enqueue(done) }
            }
            scene.onPowerupCollected = { p in store.addPowerup(p) }
        }
        .alert(L("Reklam hazır değil", "Ad not ready"), isPresented: $adNotReady) {
            Button(L("Tamam", "OK"), role: .cancel) {}
        } message: {
            Text(L("Birkaç saniye sonra tekrar dene.", "Try again in a few seconds."))
        }
        .onChange(of: scene.isOver) { _, over in
            guard over else { return }
            let earned = scene.runCoins
            var record = false
            if scene.level == nil {
                record = store.finishRun(score: scene.score, coins: earned)
                GameCenterManager.shared.submit(score: scene.score)
            } else {
                store.failLevel(runCoins: earned)
            }
            scene.consumeRunCoins()
            withAnimation(.easeOut(duration: 0.25)) {
                failResult = RunResult(score: scene.score, coins: earned, newRecord: record)
            }
        }
        .onChange(of: scene.isComplete) { _, complete in
            guard complete, let level = scene.level else { return }
            let stars = Level.stars(accuracy: scene.accuracy, bestStreak: scene.bestStreak)
            let result = store.completeLevel(level, stars: stars, runCoins: scene.runCoins)
            scene.consumeRunCoins()
            let done = store.handle(.levelComplete(level: level, stars: stars, redHits: scene.redHits))
            if !done.isEmpty { enqueue(done) }
            withAnimation(.easeOut(duration: 0.25)) {
                levelResult = LevelResultInfo(
                    stars: stars,
                    newStars: result.newStars,
                    coins: result.coins,
                    accuracy: scene.accuracy,
                    perfects: scene.perfects,
                    bestStreak: scene.bestStreak
                )
            }
        }
        .statusBarHidden()
    }

    // MARK: - Devam (ödüllü reklam)

    private var lossTitle: String? {
        switch scene.lastLoss {
        case .escaped: return nil
        case .red: return L("KIRMIZI ÇİVİ!", "RED NAIL!")
        case .bomb: return L("BOMBA PATLADI!", "BOMB WENT OFF!")
        }
    }

    private func continueRun() {
        guard !watchingAd else { return }
        if store.noAds {
            revive()
            return
        }
        watchingAd = true
        AdsManager.shared.showRewarded { earned in
            watchingAd = false
            if earned {
                revive()
            } else if !AdsManager.shared.isReady {
                adNotReady = true
            }
        }
    }

    private func revive() {
        withAnimation(.easeOut(duration: 0.2)) { failResult = nil }
        scene.revive()
    }

    // MARK: - Güçlendirici çubuğu

    private var powerupBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                ForEach(Powerup.allCases) { p in
                    powerupButton(p)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .opacity(failResult == nil && levelResult == nil ? 1 : 0)
    }

    private func powerupButton(_ p: Powerup) -> some View {
        let count = store.count(of: p)
        let left: Double = p == .zone ? scene.zoneLeft : (p == .slow ? scene.slowLeft : 0)
        let active = left > 0
        return Button {
            guard !active, count > 0 else {
                Haptics.miss()
                return
            }
            if scene.use(p) { store.consumePowerup(p) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: p.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(p.color)
                VStack(alignment: .leading, spacing: 0) {
                    Text(p.title)
                        .font(TKFont.black(12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(active ? L("AKTİF", "ACTIVE") : L("\(count) adet", "×\(count)"))
                        .font(TKFont.black(11))
                        .foregroundStyle(active ? p.color : (count > 0 ? Color.tkYellow : Color.tkMuted))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.tkCream)
            .padding(.horizontal, 10)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkPanel))
            .overlay(alignment: .bottom) {
                if active {
                    GeometryReader { geo in
                        Capsule()
                            .fill(p.color)
                            .frame(width: geo.size.width * left, height: 4)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(active ? p.color : .clear, lineWidth: 3))
            .opacity(count > 0 || active ? 1 : 0.55)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(p.title), \(active ? L("aktif", "active") : L("\(count) adet", "×\(count)"))")
    }

    // MARK: - Görev bildirimi

    private func enqueue(_ quests: [Quest]) {
        bannerQueue.append(contentsOf: quests)
        if banner == nil { showNextBanner() }
    }

    private func showNextBanner() {
        guard !bannerQueue.isEmpty else { return }
        let next = bannerQueue.removeFirst()
        Haptics.success()
        withAnimation(.spring(duration: 0.35)) { banner = next }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeIn(duration: 0.25)) { banner = nil }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showNextBanner() }
        }
    }

    // MARK: - Üst bilgi

    private var hud: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    scene.setPaused(true)
                    withAnimation(.easeOut(duration: 0.15)) { paused = true }
                } label: {
                    IconSquare(systemName: "pause.fill")
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(L("Duraklat", "Pause"))
                .disabled(failResult != nil || levelResult != nil)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<max(GameScene.maxLives, scene.lives), id: \.self) { i in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(i < scene.lives ? Color.tkRed : Color.tkPanel)
                            .scaleEffect(i < scene.lives ? 1 : 0.85)
                    }
                }
                .animation(.spring(duration: 0.3), value: scene.lives)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L("\(scene.lives) can", "\(scene.lives) lives"))
                .allowsHitTesting(false)

                Spacer()

                CoinPill(text: "+\(scene.runCoins)", iconSize: 22)
                    .allowsHitTesting(false)
            }

            if let level = scene.level {
                levelProgress(level)
                    .padding(.top, 14)
                    .padding(.horizontal, 4)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 4) {
                Text("\(scene.score)")
                    .font(TKFont.display(scene.level == nil ? 104 : 88))
                    .displayTrim(scene.level == nil ? 100 : 84)
                    .foregroundStyle(Color.tkCream)
                    .shadow(color: .tkOutline, radius: 0, x: 0, y: 6)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: scene.score)
                if scene.level == nil {
                    Text(L("EN İYİ \(store.best)", "BEST \(store.best)"))
                        .font(TKFont.extraBold(14))
                        .tracking(1)
                        .foregroundStyle(Color.tkMuted)
                }
                if scene.multiplier > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                        Text(L("x\(scene.multiplier) SERİ", "x\(scene.multiplier) STREAK"))
                    }
                    .font(TKFont.black(16))
                    .foregroundStyle(Color.tkBg)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.tkOrange))
                    .padding(.top, 8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, scene.level == nil ? 4 : 10)
            .animation(.spring(duration: 0.25), value: scene.multiplier)
            .allowsHitTesting(false)

            Spacer()
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func levelProgress(_ level: Level) -> some View {
        let goal = level.goal.count
        let fraction = goal > 0 ? CGFloat(scene.progress) / CGFloat(goal) : 0
        return VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(level.isBoss ? L("PATRON · SEVİYE \(level.number)", "BOSS · LEVEL \(level.number)") : L("SEVİYE \(level.number)", "LEVEL \(level.number)"))
                    .font(TKFont.black(14))
                    .tracking(1)
                    .foregroundStyle(level.isBoss ? Color.tkRed : Color.tkMuted)
                Spacer()
                (Text("\(scene.progress)").foregroundColor(.tkYellow) + Text(" / \(goal) \(level.goal.unit)"))
                    .font(TKFont.black(15))
                    .foregroundStyle(Color.tkCream)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.tkPanel)
                    Capsule()
                        .fill(Color.tkYellow)
                        .frame(width: max(0, geo.size.width * min(1, fraction)))
                        .animation(.easeOut(duration: 0.25), value: scene.progress)
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("Seviye \(level.number), \(scene.progress) / \(goal) \(level.goal.unit)", "Level \(level.number), \(scene.progress) / \(goal) \(level.goal.unit)"))
    }

    // MARK: - Duraklatma

    private var pauseOverlay: some View {
        ZStack {
            Color.tkDarkest.opacity(0.85)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                DisplayTitle(text: L("DURAKLADI", "PAUSED"), size: 48)
                    .padding(.bottom, 12)
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { paused = false }
                    scene.setPaused(false)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .black))
                        Text(L("DEVAM", "RESUME"))
                            .font(TKFont.display(36))
                    }
                    .frame(height: 72)
                }
                .buttonStyle(ChunkyButtonStyle())

                Button {
                    if scene.level == nil {
                        store.finishRun(score: scene.score, coins: scene.runCoins)
                    } else {
                        store.failLevel(runCoins: scene.runCoins)
                    }
                    scene.consumeRunCoins()
                    onExit()
                } label: {
                    Label(scene.level == nil ? L("Ana menü", "Main menu") : L("Haritaya dön", "Back to map"), systemImage: scene.level == nil ? "house.fill" : "map.fill")
                        .font(TKFont.black(17))
                        .foregroundStyle(Color.tkCream)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 40)
        }
    }
}
