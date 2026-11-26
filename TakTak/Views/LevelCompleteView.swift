import SwiftUI

/// Seviye geçildiğinde: yıldızlar, istatistikler, ödüller (tasarımdaki "Seviye tamamlandı").
struct LevelCompleteView: View {
    @EnvironmentObject private var store: GameStore
    let level: Level
    let stars: Int
    let newStars: Int
    let coins: Int
    let accuracy: Double
    let perfects: Int
    let bestStreak: Int
    var onNext: () -> Void
    var onReplay: () -> Void
    var onMap: () -> Void
    var onEndless: () -> Void

    @State private var shown = 0

    var body: some View {
        VStack(spacing: 0) {
            Text(L("SEVİYE \(level.number)", "LEVEL \(level.number)"))
                .font(TKFont.black(14))
                .tracking(2)
                .foregroundStyle(Color.tkMuted)
                .padding(.top, 24)
            DisplayTitle(text: level.isBoss ? L("PATRON YENİLDİ!", "BOSS DEFEATED!") : L("TAMAMLANDI!", "COMPLETE!"), size: 44, depth: 5)

            starsRow
                .padding(.top, 16)

            HStack(spacing: 10) {
                stat(L("İSABET", "ACCURACY"), L("%\(Int((accuracy * 100).rounded()))", "\(Int((accuracy * 100).rounded()))%"))
                stat(L("MÜKEMMEL", "PERFECT"), "\(perfects)")
                stat(L("EN UZUN SERİ", "BEST STREAK"), "\(bestStreak)")
            }
            .padding(.top, 14)

            rewards
                .padding(.top, 10)

            Spacer(minLength: 16)

            if level.number < Level.count {
                Button(action: onNext) {
                    HStack(spacing: 12) {
                        Text(L("SONRAKİ SEVİYE", "NEXT LEVEL"))
                            .font(TKFont.display(30))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .black))
                    }
                    .frame(height: 76)
                }
                .buttonStyle(ChunkyButtonStyle())
            } else {
                Button(action: onEndless) {
                    Text(L("BÖLÜM BİTTİ!", "CHAPTER DONE!"))
                        .font(TKFont.display(30))
                        .frame(height: 76)
                }
                .buttonStyle(ChunkyButtonStyle())
            }

            HStack(spacing: 12) {
                if stars < 3 {
                    Button(action: onReplay) {
                        Label(L("3 yıldız için tekrar", "Retry for 3 stars"), systemImage: "arrow.clockwise")
                            .font(TKFont.black(15))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tkPanelLine, lineWidth: 3))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                }
                Button(action: onMap) {
                    Label(L("Harita", "Map"), systemImage: "map.fill")
                        .font(TKFont.black(15))
                        .frame(maxWidth: stars < 3 ? 130 : .infinity)
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .foregroundStyle(Color.tkCream)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tkBg.ignoresSafeArea())
        .onAppear(perform: revealStars)
    }

    // MARK: - Yıldızlar

    private var starsRow: some View {
        ZStack {
            bigStar(index: 0, size: 84).rotationEffect(.degrees(-14)).offset(x: -96, y: 22)
            bigStar(index: 2, size: 84).rotationEffect(.degrees(14)).offset(x: 96, y: 22)
            bigStar(index: 1, size: 106)
        }
        .frame(height: 124)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("\(stars) yıldız", "\(stars) stars"))
    }

    private func bigStar(index: Int, size: CGFloat) -> some View {
        let earned = index < stars
        let visible = index < shown
        return ZStack {
            StarShape()
                .fill(Color.tkPanel)
            StarShape()
                .fill(Color.tkYellow)
                .scaleEffect(visible && earned ? 1 : 0.2)
                .opacity(visible && earned ? 1 : 0)
            StarShape()
                .stroke(Color.tkOutline, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }

    /// Yıldızları sırayla, her birinde "TAK" sesi ve titreşimle gösterir.
    private func revealStars() {
        for i in 0..<stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.35) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { shown = i + 1 }
                Haptics.perfect()
                SoundFX.shared.play(.perfect)
            }
        }
    }

    // MARK: - İstatistik ve ödüller

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(TKFont.extraBold(12))
                .foregroundStyle(Color.tkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(TKFont.black(24))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
        .accessibilityElement(children: .combine)
    }

    private var rewards: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L("Ödüller", "Rewards"))
                    .font(TKFont.black(15))
                Spacer()
                HStack(spacing: 14) {
                    HStack(spacing: 6) {
                        CoinIcon(size: 18)
                        Text("+\(coins)")
                    }
                    HStack(spacing: 4) {
                        StarIcon(filled: true, size: 18)
                        Text("+\(newStars)")
                    }
                }
                .font(TKFont.black(17))
            }
            HStack(spacing: 12) {
                ChestIcon()
                    .scaleEffect(0.85)
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.chestReady
                         ? L("Sandık hazır! Haritadan aç.", "Chest ready! Open it on the map.")
                         : L("Sandığa \(GameStore.chestCost - store.chestProgress) yıldız kaldı", "\(GameStore.chestCost - store.chestProgress) stars to the chest"))
                        .font(TKFont.black(14))
                        .foregroundStyle(store.chestReady ? Color.tkGreen : Color.tkCream)
                    ProgressBar(fraction: Double(store.chestProgress) / Double(GameStore.chestCost),
                                color: store.chestReady ? .tkGreen : .tkYellow)
                        .frame(height: 12)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
        .accessibilityElement(children: .combine)
    }
}
