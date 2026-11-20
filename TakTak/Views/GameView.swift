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

    init(mode: GameMode, hammer: HammerVariant, onExit: @escaping () -> Void, onRequestLevel: @escaping (Int) -> Void) {
        self.mode = mode
        let level: Level?
        if case .level(let n) = mode { level = Level.get(n) } else { level = nil }
        _scene = StateObject(wrappedValue: GameScene(hammer: hammer, level: level))
        self.onExit = onExit
        self.onRequestLevel = onRequestLevel
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, isPaused: paused, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            hud

            if paused {
                pauseOverlay
                    .transition(.opacity)
            }

            if let r = failResult {
                GameOverView(
                    title: scene.level == nil ? nil : "SEVİYE BAŞARISIZ",
                    score: r.score,
                    best: store.best,
                    showBest: scene.level == nil,
                    newRecord: r.newRecord,
                    coinsEarned: r.coins,
                    canContinue: !scene.hasContinued,
                    escaped: scene.lastLoss == .escaped,
                    menuTitle: scene.level == nil ? "Ana menü" : "Harita",
                    onContinue: {
                        // Şimdilik her oyunda bir kez ücretsiz devam hakkı.
                        // İleride ödüllü reklam eklenirse (ör. AdMob RewardedAd), reklam izlenince
                        // scene.revive() çağrılmalı ve butonun yazısı buna göre değiştirilmeli.
                        withAnimation(.easeOut(duration: 0.2)) { failResult = nil }
                        scene.revive()
                    },
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
        .onChange(of: scene.isOver) { _, over in
            guard over else { return }
            let earned = scene.runCoins
            var record = false
            if scene.level == nil {
                record = store.finishRun(score: scene.score, coins: earned)
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
                .accessibilityLabel("Duraklat")
                .disabled(failResult != nil || levelResult != nil)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<GameScene.maxLives, id: \.self) { i in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(i < scene.lives ? Color.tkRed : Color.tkPanel)
                            .scaleEffect(i < scene.lives ? 1 : 0.85)
                    }
                }
                .animation(.spring(duration: 0.3), value: scene.lives)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(scene.lives) can")
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
                    Text("EN İYİ \(store.best)")
                        .font(TKFont.extraBold(14))
                        .tracking(1)
                        .foregroundStyle(Color.tkMuted)
                }
                if scene.multiplier > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                        Text("x\(scene.multiplier) SERİ")
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
                Text(level.isBoss ? "PATRON · SEVİYE \(level.number)" : "SEVİYE \(level.number)")
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
        .accessibilityLabel("Seviye \(level.number), \(scene.progress) / \(goal) \(level.goal.unit)")
    }

    // MARK: - Duraklatma

    private var pauseOverlay: some View {
        ZStack {
            Color.tkDarkest.opacity(0.85)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                DisplayTitle(text: "DURAKLADI", size: 48)
                    .padding(.bottom, 12)
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { paused = false }
                    scene.setPaused(false)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .black))
                        Text("DEVAM")
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
                    Label(scene.level == nil ? "Ana menü" : "Haritaya dön", systemImage: scene.level == nil ? "house.fill" : "map.fill")
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
