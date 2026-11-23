import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    private enum Screen: Equatable {
        case menu, map, shop, quests
        case game(GameMode)
    }

    private enum Overlay: Equatable {
        case daily
        case feature(Feature, level: Int)
        case intro(Int)
    }

    @State private var screen: Screen = .menu
    @State private var overlay: Overlay?
    @State private var gameID = UUID()
    @State private var checkedDaily = false

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(
                    onPlay: {
                        if store.allLevelsDone {
                            startEndless()
                        } else {
                            requestLevel(store.currentLevel)
                        }
                    },
                    onMap: { screen = .map },
                    onEndless: startEndless,
                    onShop: { screen = .shop },
                    onDaily: { show(.daily) },
                    onQuests: { screen = .quests }
                )
                .transition(.opacity)
            case .map:
                LevelMapView(
                    onBack: { screen = .menu },
                    onSelect: { requestLevel($0) }
                )
                .transition(.opacity)
            case .shop:
                ShopView(onBack: { screen = .menu })
                    .transition(.move(edge: .trailing))
            case .quests:
                QuestsView(onBack: { screen = .menu })
                    .transition(.move(edge: .trailing))
            case .game(let mode):
                GameView(
                    mode: mode,
                    hammer: store.equipped,
                    onExit: {
                        if case .level = mode { screen = .map } else { screen = .menu }
                    },
                    onRequestLevel: { requestLevel($0) }
                )
                .id(gameID)
                .transition(.opacity)
            }

            if let overlay {
                overlayView(overlay)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: screen)
        .animation(.easeOut(duration: 0.2), value: overlay)
        .onAppear {
            // Açılışta ödül varsa göster: oyuncuyu her gün geri getiren şey.
            store.refreshQuestsIfNeeded()
            guard !checkedDaily else { return }
            checkedDaily = true
            if store.dailyState.canClaim {
                overlay = .daily
            }
        }
    }

    @ViewBuilder
    private func overlayView(_ o: Overlay) -> some View {
        switch o {
        case .daily:
            DailyRewardView(onClose: { overlay = nil })
        case .feature(let feature, let level):
            FeatureIntroView(feature: feature) {
                store.markSeen(feature)
                overlay = .intro(level)
            }
        case .intro(let n):
            LevelIntroView(
                level: Level.get(n),
                onStart: { startLevel(n) },
                onClose: { overlay = nil }
            )
        }
    }

    // MARK: - Akış

    private func show(_ o: Overlay) {
        overlay = o
    }

    /// Seviyeyi aç: önce (gerekirse) yenilik tanıtımı, sonra hedef kartı.
    private func requestLevel(_ n: Int) {
        guard n <= Level.count, store.isLevelOpen(n) else {
            screen = .map
            return
        }
        if case .game = screen { screen = .map }
        let level = Level.get(n)
        if let f = level.newFeature, !store.hasSeen(f) {
            overlay = .feature(f, level: n)
        } else {
            overlay = .intro(n)
        }
    }

    private func startLevel(_ n: Int) {
        overlay = nil
        gameID = UUID()
        screen = .game(.level(n))
    }

    private func startEndless() {
        overlay = nil
        gameID = UUID()
        screen = .game(.endless)
    }
}
