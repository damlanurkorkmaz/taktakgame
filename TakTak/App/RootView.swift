import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: GameStore

    private enum Screen { case menu, game, shop }

    @State private var screen: Screen = .menu
    @State private var showDaily = false
    @State private var gameID = UUID()
    @State private var checkedDaily = false

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(
                    onPlay: {
                        gameID = UUID()
                        screen = .game
                    },
                    onShop: { screen = .shop },
                    onDaily: { withAnimation(.easeOut(duration: 0.2)) { showDaily = true } }
                )
                .transition(.opacity)
            case .game:
                GameView(hammer: store.equipped, onExit: { screen = .menu })
                    .id(gameID)
                    .transition(.opacity)
            case .shop:
                ShopView(onBack: { screen = .menu })
                    .transition(.move(edge: .trailing))
            }

            if showDaily {
                DailyRewardView(onClose: { withAnimation(.easeOut(duration: 0.2)) { showDaily = false } })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: screen)
        .onAppear {
            // Açılışta ödül varsa göster: oyuncuyu her gün geri getiren şey.
            guard !checkedDaily else { return }
            checkedDaily = true
            if store.dailyState.canClaim {
                showDaily = true
            }
        }
    }
}
