import SwiftUI

struct GameOverView: View {
    let score: Int
    let best: Int
    let newRecord: Bool
    let coinsEarned: Int
    let canContinue: Bool
    var onContinue: () -> Void
    var onRetry: () -> Void
    var onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            let small = geo.size.height < 720
            let tall = geo.size.height >= 800
            VStack(spacing: 0) {
                DisplayTitle(text: "ÇİVİ EĞİLDİ!", size: small ? 46 : 56, color: .tkRed, shadow: .tkRedShadow, depth: 5)
                    .rotationEffect(.degrees(-3))
                    .padding(.top, small ? 8 : 28)

                if tall {
                    bentNail
                        .padding(.top, 12)
                }

                scoreCard
                    .padding(.top, small ? 16 : 24)

                if canContinue {
                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Kaldığın yerden devam et (1 hak)")
                                .font(TKFont.black(16))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(Color.tkGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tkGreen, lineWidth: 3))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 20)
                }

                Button(action: onRetry) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 28, weight: .black))
                        Text("TEKRAR")
                            .font(TKFont.display(38))
                    }
                    .frame(height: 76)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 14)

                Spacer(minLength: 12)

                HStack(spacing: 12) {
                    Button(action: onMenu) {
                        panelLabel("Ana menü", icon: "house.fill")
                    }
                    .buttonStyle(PressableStyle())

                    ShareLink(item: "Tak Tak!'ta \(score) puan yaptım. Beni geçebilir misin?") {
                        panelLabel("Paylaş", icon: "square.and.arrow.up")
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .foregroundStyle(Color.tkCream)
        }
        .background(Color.tkBg.ignoresSafeArea())
    }

    private var bentNail: some View {
        let img = BeltArt.sceneImage(
            width: 342,
            compact: true,
            nails: [
                .init(x: 70, state: .driven),
                .init(x: 195, state: .bent),
                .init(x: 320, state: .driven)
            ],
            nailSize: 90
        )
        return Image(uiImage: img)
            .accessibilityLabel("Eğilmiş çivi")
    }

    private var scoreCard: some View {
        VStack(spacing: 4) {
            if newRecord {
                Text("YENİ REKOR!")
                    .font(TKFont.black(14))
                    .tracking(1)
                    .foregroundStyle(Color(hex: 0x1C3A2E))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.tkGreen))
                    .padding(.bottom, 4)
            }
            Text("SKOR")
                .font(TKFont.extraBold(14))
                .tracking(1)
                .foregroundStyle(Color.tkMuted)
            Text("\(score)")
                .font(TKFont.display(84))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .displayTrim(80)
            HStack(spacing: 12) {
                statBox(title: "EN İYİ") {
                    Text("\(best)")
                }
                statBox(title: "KAZANILAN") {
                    HStack(spacing: 6) {
                        CoinIcon(size: 20)
                        Text("+\(coinsEarned)")
                    }
                }
            }
            .padding(.top, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.tkPanel))
    }

    private func statBox<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(TKFont.extraBold(13))
                .foregroundStyle(Color.tkMuted)
            content()
                .font(TKFont.black(24))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkBg))
    }

    private func panelLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(TKFont.extraBold(15))
            .foregroundStyle(Color.tkCream)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkPanel))
    }
}
