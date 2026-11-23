import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var store: GameStore
    var onPlay: () -> Void
    var onMap: () -> Void
    var onEndless: () -> Void
    var onShop: () -> Void
    var onDaily: () -> Void
    var onQuests: () -> Void

    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            let small = geo.size.height < 720
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    CoinPill(text: store.coins.tk)
                    HStack(spacing: 6) {
                        StarIcon(filled: true, size: 20)
                        Text("\(store.totalStars)")
                            .font(TKFont.black(17))
                            .monospacedDigit()
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.tkPanel))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(store.totalStars) yıldız")
                    Spacer()
                    Button { showSettings = true } label: {
                        IconSquare(systemName: "slider.horizontal.3")
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Ayarlar")
                }

                Spacer(minLength: 4)

                VStack(spacing: -4) {
                    DisplayTitle(text: "TAK", size: small ? 58 : 76)
                    DisplayTitle(text: "TAK!", size: small ? 58 : 76)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Tak Tak")
                .accessibilityAddTraits(.isHeader)

                Text("Doğru anda vur. Çiviyi tek seferde göm.")
                    .font(TKFont.extraBold(16))
                    .foregroundStyle(Color.tkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                // Görsel ekran genişliğinde (390); sütunun kenar boşluklarından taşar.
                // overlay içinde olduğu için sütunun genişliğini etkilemez, ekran kaymaz.
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: small ? 150 : 200)
                    .overlay {
                        MenuHero(hammer: store.equipped)
                            .scaleEffect(small ? 0.65 : 0.87)
                    }
                    .padding(.top, 8)

                QuestStrip(action: onQuests)
                    .padding(.top, 10)

                Button(action: onPlay) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 28, weight: .black))
                        Text(store.allLevelsDone ? "SONSUZ MOD" : "SEVİYE \(store.currentLevel)")
                            .font(TKFont.display(40))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(height: small ? 66 : 76)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 16)

                Spacer(minLength: 12)

                HStack(spacing: 12) {
                    navButton("Harita", icon: "map.fill", dot: store.chestReady, action: onMap)
                    if store.endlessUnlocked && !store.allLevelsDone {
                        navButton("Sonsuz", icon: "infinity", dot: false, action: onEndless)
                    }
                    navButton("Mağaza", icon: "bag.fill", dot: false, action: onShop)
                    navButton("Ödül", icon: "gift.fill", dot: store.dailyState.canClaim, action: onDaily)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .foregroundStyle(Color.tkCream)
        }
        .background(Color.tkBg.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .presentationDetents([.height(300)])
        }
    }

    private func navButton(_ title: String, icon: String, dot: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                Text(title)
                    .font(TKFont.extraBold(14))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.tkCream)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
            .overlay(alignment: .topTrailing) {
                if dot {
                    Circle()
                        .fill(Color.tkRed)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.tkPanel, lineWidth: 3))
                        .padding(12)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(dot ? "\(title), yeni" : title)
    }
}

/// Bant, çivi ve çekiçten oluşan menü görseli.
struct MenuHero: View {
    let hammer: HammerVariant

    var body: some View {
        let belt = BeltArt.sceneImage(
            width: 390,
            compact: true,
            nails: [
                .init(x: 70, state: .driven),
                .init(x: 205, state: .up),
                .init(x: 340, state: .driven)
            ],
            nailSize: 70
        )
        ZStack(alignment: .topLeading) {
            Image(uiImage: belt)
                .offset(y: 200 - belt.size.height)
            Image(uiImage: HammerArt.image(hammer, size: 200, angle: -35, shadow: false))
                .offset(x: 174, y: -26)
        }
        .frame(width: 390, height: 230, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}
