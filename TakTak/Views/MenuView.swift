import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var store: GameStore
    var onPlay: () -> Void
    var onShop: () -> Void
    var onDaily: () -> Void

    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            let small = geo.size.height < 720
            VStack(spacing: 0) {
                HStack {
                    CoinPill(text: store.coins.tk)
                    Spacer()
                    Button { showSettings = true } label: {
                        IconSquare(systemName: "slider.horizontal.3")
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Ayarlar")
                }

                Spacer(minLength: 4)

                VStack(spacing: -4) {
                    DisplayTitle(text: "TAK", size: small ? 66 : 86)
                    DisplayTitle(text: "TAK!", size: small ? 66 : 86)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Tak Tak")
                .accessibilityAddTraits(.isHeader)

                Text("Doğru anda vur. Çiviyi tek seferde göm.")
                    .font(TKFont.extraBold(16))
                    .foregroundStyle(Color.tkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                MenuHero(hammer: store.equipped)
                    .scaleEffect(small ? 0.78 : 1)
                    .frame(height: small ? 180 : 230)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Color.tkYellow)
                    Text("EN İYİ: \(store.best)")
                        .font(TKFont.black(18))
                        .tracking(1)
                }
                .padding(.top, 12)

                Button(action: onPlay) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 28, weight: .black))
                        Text("OYNA")
                            .font(TKFont.display(40))
                    }
                    .frame(height: small ? 66 : 76)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 16)

                Spacer(minLength: 12)

                HStack(spacing: 12) {
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
