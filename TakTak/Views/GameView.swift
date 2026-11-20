import SpriteKit
import SwiftUI

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @StateObject private var scene: GameScene
    var onExit: () -> Void

    @State private var result: RunResult?
    @State private var paused = false

    struct RunResult: Equatable {
        let score: Int
        let coins: Int
        let newRecord: Bool
    }

    init(hammer: HammerVariant, onExit: @escaping () -> Void) {
        _scene = StateObject(wrappedValue: GameScene(hammer: hammer))
        self.onExit = onExit
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

            if let r = result {
                GameOverView(
                    score: r.score,
                    best: store.best,
                    newRecord: r.newRecord,
                    coinsEarned: r.coins,
                    canContinue: !scene.hasContinued,
                    onContinue: {
                        // Şimdilik her oyunda bir kez ücretsiz devam hakkı.
                        // İleride ödüllü reklam eklenirse (ör. AdMob RewardedAd), reklam izlenince
                        // scene.revive() çağrılmalı ve butonun yazısı buna göre değiştirilmeli.
                        withAnimation(.easeOut(duration: 0.2)) { result = nil }
                        scene.revive()
                    },
                    onRetry: {
                        withAnimation(.easeOut(duration: 0.2)) { result = nil }
                        scene.restart()
                    },
                    onMenu: onExit
                )
                .transition(.opacity)
            }
        }
        .background(Color.tkBg.ignoresSafeArea())
        .onChange(of: scene.isOver) { _, over in
            guard over else { return }
            let earned = scene.runCoins
            let record = store.finishRun(score: scene.score, coins: earned)
            scene.consumeRunCoins()
            withAnimation(.easeOut(duration: 0.25)) {
                result = RunResult(score: scene.score, coins: earned, newRecord: record)
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
                .disabled(result != nil)

                Spacer()

                CoinPill(text: "+\(scene.runCoins)", iconSize: 22)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 4) {
                Text("\(scene.score)")
                    .font(TKFont.display(104))
                    .displayTrim(100)
                    .foregroundStyle(Color.tkCream)
                    .shadow(color: .tkOutline, radius: 0, x: 0, y: 6)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: scene.score)
                Text("EN İYİ \(store.best)")
                    .font(TKFont.extraBold(14))
                    .tracking(1)
                    .foregroundStyle(Color.tkMuted)
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
            .animation(.spring(duration: 0.25), value: scene.multiplier)
            .allowsHitTesting(false)

            Spacer()
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
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
                    store.finishRun(score: scene.score, coins: scene.runCoins)
                    scene.consumeRunCoins()
                    onExit()
                } label: {
                    Label("Ana menü", systemImage: "house.fill")
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
