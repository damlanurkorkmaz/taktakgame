import SwiftUI

struct GameOverView: View {
    /// nil ise kayıp sebebine göre başlık (L("ÇİVİ KAÇTI!", "NAIL ESCAPED!") / L("KIRMIZI ÇİVİ!", "RED NAIL!"))
    var title: String? = nil
    let score: Int
    let best: Int
    /// Sonsuz modda rekor kutusu gösterilir
    var showBest = true
    let newRecord: Bool
    let coinsEarned: Int
    let canContinue: Bool
    /// true: son can kaçan çiviyle gitti, false: kırmızı çiviye vurulduğu için.
    var escaped = true
    /// Kırmızı / bomba gibi özel kayıp başlığı
    var lossTitle: String? = nil
    var menuTitle = L("Ana menü", "Main menu")
    /// Devam hakkı ödüllü reklamla mı (reklamsız alındıysa false)
    var continueWithAd = true
    /// Rekor kartında gösterilecek çekiç
    var hammer: HammerVariant = .klasik
    var onContinue: () -> Void
    var onRetry: () -> Void
    var onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            let small = geo.size.height < 720
            let tall = geo.size.height >= 800
            VStack(spacing: 0) {
                DisplayTitle(text: headline, size: titleSize(small: small), color: .tkRed, shadow: .tkRedShadow, depth: 5)
                    .rotationEffect(.degrees(-3))
                    .padding(.top, small ? 8 : 28)

                if tall {
                    bentNail(width: geo.size.width - 48)
                        .padding(.top, 12)
                }

                scoreCard
                    .padding(.top, small ? 16 : 24)

                if canContinue {
                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Image(systemName: continueWithAd ? "play.rectangle.fill" : "heart.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text(continueWithAd ? L("Reklam izle, bir can al", "Watch an ad for a life") : L("Bir can al, devam et (1 hak)", "Take a life and continue (once)"))
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
                        Text(L("TEKRAR", "RETRY"))
                            .font(TKFont.display(38))
                    }
                    .frame(height: 76)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 14)

                if newRecord && showBest, let card = ShareCard.image(score: score, hammer: hammer) {
                    ShareLink(item: Image(uiImage: card),
                              preview: SharePreview(L("Tak Tak! rekorum: \(score)", "My Tak Tak! record: \(score)"), image: Image(uiImage: card))) {
                        Label(L("Rekor kartını paylaş", "Share record card"), systemImage: "sparkles")
                            .font(TKFont.black(16))
                            .foregroundStyle(Color.tkBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkOrange))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 12)
                }

                Spacer(minLength: 12)

                HStack(spacing: 12) {
                    Button(action: onMenu) {
                        panelLabel(menuTitle, icon: menuTitle == L("Ana menü", "Main menu") ? "house.fill" : "map.fill")
                    }
                    .buttonStyle(PressableStyle())

                    ShareLink(item: L("Tak Tak!'ta \(score) puan yaptım. Beni geçebilir misin?", "I scored \(score) in Tak Tak! Can you beat me?")) {
                        panelLabel(L("Paylaş", "Share"), icon: "square.and.arrow.up")
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

    private var headline: String {
        title ?? lossTitle ?? (escaped ? L("ÇİVİ KAÇTI!", "NAIL ESCAPED!") : L("KIRMIZI ÇİVİ!", "RED NAIL!"))
    }

    private func titleSize(small: Bool) -> CGFloat {
        headline.count > 12 ? (small ? 34 : 40) : (small ? 46 : 56)
    }

    private func bentNail(width: CGFloat) -> some View {
        let img = BeltArt.sceneImage(
            width: min(342, width),
            compact: true,
            nails: [
                .init(x: 70, state: .driven),
                .init(x: 195, state: escaped ? .driven : .bent, tint: escaped ? .steel : .red),
                .init(x: escaped ? 305 : 320, state: escaped ? .up : .driven)
            ],
            nailSize: 90
        )
        return Image(uiImage: img)
            .accessibilityLabel(escaped ? L("Kaçan çivi", "Escaped nail") : L("Vurulmuş kırmızı çivi", "Hit red nail"))
    }

    private var scoreCard: some View {
        VStack(spacing: 4) {
            if newRecord {
                Text(L("YENİ REKOR!", "NEW RECORD!"))
                    .font(TKFont.black(14))
                    .tracking(1)
                    .foregroundStyle(Color(hex: 0x1C3A2E))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.tkGreen))
                    .padding(.bottom, 4)
            }
            Text(L("SKOR", "SCORE"))
                .font(TKFont.extraBold(14))
                .tracking(1)
                .foregroundStyle(Color.tkMuted)
            Text("\(score)")
                .font(TKFont.display(84))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .displayTrim(80)
            HStack(spacing: 12) {
                if showBest {
                    statBox(title: L("EN İYİ", "BEST")) {
                        Text("\(best)")
                    }
                }
                statBox(title: L("KAZANILAN", "EARNED")) {
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
