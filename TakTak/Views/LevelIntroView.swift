import SwiftUI

/// Seviye başlamadan önce gösterilen hedef kartı (tasarımdaki "Seviye hedefi").
struct LevelIntroView: View {
    let level: Level
    var onStart: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.tkDarkest.opacity(0.94)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    closeButton(onClose)
                }
                .padding(.bottom, -18)

                Text("BÖLÜM 1 · \(Level.chapterTitle)")
                    .font(TKFont.extraBold(13))
                    .tracking(2)
                    .foregroundStyle(Color.tkMuted)
                DisplayTitle(text: "SEVİYE \(level.number)", size: 46, depth: 5)

                if level.isBoss {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text("PATRON SEVİYESİ")
                    }
                    .font(TKFont.black(13))
                    .tracking(1)
                    .foregroundStyle(Color.tkCream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: 0xE0503F)))
                    .padding(.top, 6)
                }

                HStack(spacing: 16) {
                    Image(uiImage: NailArt.image(.up, goalTint, size: 60))
                        .frame(width: 64, height: 64)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkBg))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("HEDEF")
                            .font(TKFont.extraBold(13))
                            .tracking(1)
                            .foregroundStyle(Color.tkMuted)
                        Text(level.goal.title)
                            .font(TKFont.display(28))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
                .padding(.top, 16)
                .accessibilityElement(children: .combine)

                VStack(spacing: 8) {
                    starRow(1, "Seviyeyi bitir")
                    starRow(2, "%\(Int(Level.twoStarAccuracy * 100)) isabetle bitir")
                    starRow(3, "%\(Int(Level.threeStarAccuracy * 100)) isabet ya da \(Level.threeStarStreak)'luk seri")
                }
                .padding(.top, 12)

                if let feature = level.newFeature {
                    HStack(spacing: 12) {
                        Image(uiImage: NailArt.image(.up, feature.tint, size: 58))
                            .frame(width: 44, height: 58)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("YENİ")
                                .font(TKFont.black(11))
                                .tracking(1)
                                .foregroundStyle(Color.tkBg)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.tkOrange))
                            Text(feature.title)
                                .font(TKFont.black(15))
                            Text(feature.short)
                                .font(TKFont.extraBold(13))
                                .foregroundStyle(Color.tkMuted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tkOrange, style: StrokeStyle(lineWidth: 3, dash: [8, 6])))
                    .padding(.top, 12)
                    .accessibilityElement(children: .combine)
                }

                HStack(spacing: 8) {
                    ForEach(0..<GameScene.maxLives, id: \.self) { _ in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.tkRed)
                    }
                    Text("\(GameScene.maxLives) can")
                        .font(TKFont.extraBold(14))
                        .foregroundStyle(Color.tkMuted)
                        .padding(.leading, 4)
                }
                .padding(.top, 16)
                .accessibilityElement(children: .combine)

                Button(action: onStart) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .black))
                        Text("BAŞLA")
                            .font(TKFont.display(34))
                    }
                    .frame(height: 70)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 18)
            }
            .padding(EdgeInsets(top: 14, leading: 22, bottom: 22, trailing: 22))
            .foregroundStyle(Color.tkCream)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkBg))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tkPanel, lineWidth: 3))
            .padding(20)
        }
    }

    private var goalTint: NailTint {
        if case .hard = level.goal { return .hard }
        return .steel
    }

    private func starRow(_ count: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    StarIcon(filled: i < count, size: 18)
                }
            }
            .frame(width: 62, alignment: .leading)
            Text(text)
                .font(TKFont.extraBold(15))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x33271F)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) yıldız: \(text)")
    }
}

/// Yeni bir çivi türü ya da mekanik ilk kez çıktığında gösterilen kart (tasarımdaki "Yeni çivi").
struct FeatureIntroView: View {
    let feature: Feature
    var onDone: () -> Void

    var body: some View {
        ZStack {
            Color.tkDarkest.opacity(0.94)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(feature.badge)
                    .font(TKFont.black(13))
                    .tracking(1)
                    .foregroundStyle(Color.tkBg)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.tkOrange))

                illustration
                    .padding(.top, 16)

                DisplayTitle(text: feature.title, size: 40,
                             color: feature == .red ? .tkRed : .tkYellow,
                             shadow: feature == .red ? .tkRedShadow : .tkBrownShadow,
                             depth: 4)
                    .padding(.top, 8)

                Text(feature.text)
                    .font(TKFont.extraBold(17))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)

                if feature == .red {
                    HStack(spacing: 12) {
                        doDont(tint: .steel, ok: true)
                        doDont(tint: .red, ok: false)
                    }
                    .padding(.top, 20)
                }

                Button(action: onDone) {
                    Text("ANLADIM")
                        .font(TKFont.display(34))
                        .frame(height: 68)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 22)
            }
            .padding(EdgeInsets(top: 26, leading: 22, bottom: 22, trailing: 22))
            .foregroundStyle(Color.tkCream)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkBg))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tkPanel, lineWidth: 3))
            .padding(20)
        }
    }

    @ViewBuilder
    private var illustration: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(RadialGradient(colors: [feature == .red ? Color(hex: 0x5A2A20) : Color.tkPanelHi, Color.tkBg],
                                     center: .center, startRadius: 0, endRadius: 110))
                .frame(width: 210, height: 200)
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(hex: 0xEBB273), Color(hex: 0xC98A4B), Color(hex: 0x95602F)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.tkOutline, lineWidth: 3))
                .frame(width: 160, height: 26)
                .padding(.bottom, 30)
            Group {
                switch feature {
                case .pairs:
                    HStack(spacing: -40) {
                        Image(uiImage: NailArt.image(.up, .steel, size: 120))
                        Image(uiImage: NailArt.image(.up, .steel, size: 120))
                    }
                case .tempo:
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 90, weight: .bold))
                        .foregroundStyle(Color.tkOrange)
                        .padding(.bottom, 6)
                default:
                    Image(uiImage: NailArt.image(.up, feature.tint, size: 140))
                }
            }
            .padding(.bottom, 56)
        }
        .frame(height: 210)
        .accessibilityHidden(true)
    }

    private func doDont(tint: NailTint, ok: Bool) -> some View {
        VStack(spacing: 8) {
            Image(uiImage: NailArt.image(.up, tint, size: 70))
            HStack(spacing: 6) {
                Image(systemName: ok ? "checkmark" : "xmark")
                    .font(.system(size: 16, weight: .black))
                Text(ok ? "VUR" : "VURMA")
                    .font(TKFont.black(16))
            }
            .foregroundStyle(ok ? Color.tkGreen : Color.tkRed)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(ok ? Color.tkGreen : Color.tkRed, lineWidth: 3))
        .accessibilityElement(children: .combine)
    }
}

func closeButton(_ action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "xmark")
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(Color.tkMuted)
            .frame(width: 44, height: 44)
    }
    .accessibilityLabel("Kapat")
}
