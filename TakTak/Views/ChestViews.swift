import SwiftUI

/// Sandıktan çıkabilecek tek bir ödül.
enum ChestPrize: Identifiable, Hashable {
    case coins(Int)
    case stars(Int)
    case hammer(HammerVariant)

    var id: String {
        switch self {
        case .coins: return "coins"
        case .stars: return "stars"
        case .hammer(let h): return "hammer-\(h.rawValue)"
        }
    }
}

/// Kapağı açılan, sallanan, içinden ışık ve para fışkıran ahşap sandık.
struct AnimatedChest: View {
    var open: Bool
    /// Kapalıyken ara ara sallansın mı
    var wiggle: Bool = true

    @State private var burst = false
    @State private var fade = false

    private let wood = Color(hex: 0xB97A3C)
    private let woodDark = Color(hex: 0x8A5527)
    private let woodLight = Color(hex: 0xD99350)
    private let metal = Color(hex: 0xE0A93C)
    private let metalDark = Color(hex: 0x9C6A1E)

    var body: some View {
        TimelineView(.animation(paused: open || !wiggle)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let phase = t.truncatingRemainder(dividingBy: 1.8)
            let angle = (!open && wiggle && phase < 0.45) ? sin(phase * 42) * 5 * (1 - phase / 0.45) : 0
            chest
                .rotationEffect(.degrees(angle), anchor: .bottom)
        }
        .frame(width: 220, height: 210)
        .onChange(of: open) { _, isOpen in
            guard isOpen else { return }
            withAnimation(.easeOut(duration: 0.7)) { burst = true }
            withAnimation(.easeIn(duration: 0.4).delay(0.55)) { fade = true }
        }
        .accessibilityHidden(true)
    }

    private var chest: some View {
        ZStack {
            // Arkadaki ışık
            if open {
                Rays()
                    .frame(width: 320, height: 320)
                    .offset(y: -10)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
                Circle()
                    .fill(RadialGradient(colors: [Color.tkYellow.opacity(0.75), Color.tkYellow.opacity(0)],
                                         center: .center, startRadius: 4, endRadius: 120))
                    .frame(width: 260, height: 260)
                    .offset(y: -20)
                    .transition(.opacity)
            }

            // Gövde
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(wood)
                    .overlay {
                        VStack(spacing: 26) {
                            Rectangle().fill(woodDark.opacity(0.55)).frame(height: 3)
                            Rectangle().fill(woodDark.opacity(0.55)).frame(height: 3)
                        }
                        .padding(.top, 14)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(woodDark).frame(height: 10)
                            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14))
                    }
                    .overlay {
                        HStack {
                            band
                            Spacer()
                            band
                        }
                        .padding(.horizontal, 22)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tkOutline, lineWidth: 4))

                // İç kısım (açıkken görünür)
                if open {
                    ZStack {
                        Capsule().fill(Color(hex: 0x3A2414))
                        HStack(spacing: -6) {
                            ForEach(0..<7, id: \.self) { i in
                                Circle()
                                    .fill(Color.tkYellow)
                                    .overlay(Circle().strokeBorder(Color.tkYellowDeep, lineWidth: 2))
                                    .frame(width: 20, height: 20)
                                    .offset(y: i.isMultiple(of: 2) ? -3 : 2)
                            }
                        }
                    }
                    .frame(width: 164, height: 22)
                    .offset(y: -8)
                    .transition(.opacity)
                }

                // Kilit
                RoundedRectangle(cornerRadius: 6)
                    .fill(metal)
                    .overlay(
                        VStack(spacing: 0) {
                            Circle().fill(Color.tkOutline).frame(width: 7, height: 7)
                            Rectangle().fill(Color.tkOutline).frame(width: 3, height: 7)
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.tkOutline, lineWidth: 3))
                    .frame(width: 30, height: 34)
                    .offset(y: open ? 70 : -6)
                    .rotationEffect(.degrees(open ? 35 : 0))
                    .opacity(open ? 0 : 1)
            }
            .frame(width: 190, height: 100)
            .offset(y: 48)

            // Kapak
            UnevenRoundedRectangle(topLeadingRadius: 34, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 34)
                .fill(woodLight)
                .overlay(alignment: .top) {
                    Capsule().fill(Color.white.opacity(0.18)).frame(width: 120, height: 6).padding(.top, 9)
                }
                .overlay {
                    HStack {
                        band
                        Spacer()
                        band
                    }
                    .padding(.horizontal, 22)
                }
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 34, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 34)
                        .strokeBorder(Color.tkOutline, lineWidth: 4)
                )
                .frame(width: 200, height: 62)
                .rotation3DEffect(.degrees(open ? 118 : 0), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
                .offset(y: open ? -32 : -27)

            // Fışkıran paralar
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) / 12 * .pi + .pi
                let r: Double = 95 + Double(i % 3) * 22
                CoinIcon(size: 22)
                    .offset(x: burst ? cos(a) * r : 0, y: burst ? sin(a) * r - 20 : 20)
                    .scaleEffect(burst ? 1 : 0.3)
                    .opacity(open && !fade ? 1 : 0)
            }
        }
    }

    private var band: some View {
        Rectangle()
            .fill(metal)
            .overlay(alignment: .trailing) { Rectangle().fill(metalDark).frame(width: 4) }
            .frame(width: 16)
            .overlay(Rectangle().strokeBorder(Color.tkOutline, lineWidth: 2))
    }
}

/// Yavaşça dönen ışık huzmeleri
private struct Rays: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(LinearGradient(colors: [Color.tkYellow.opacity(0.55), Color.tkYellow.opacity(0)],
                                             startPoint: .bottom, endPoint: .top))
                        .frame(width: 26, height: 160)
                        .offset(y: -80)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .rotationEffect(.degrees(t * 18))
        }
        .allowsHitTesting(false)
    }
}

/// Tek bir ödül kutucuğu
struct ChestPrizeTile: View {
    let prize: ChestPrize

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkBg))
            VStack(alignment: .leading, spacing: 2) {
                Text(caption)
                    .font(TKFont.black(12))
                    .tracking(1)
                    .foregroundStyle(captionColor)
                Text(value)
                    .font(TKFont.display(26))
                    .displayTrim(26)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(captionColor.opacity(0.9), lineWidth: 3))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var icon: some View {
        switch prize {
        case .coins: CoinIcon(size: 34)
        case .stars: StarIcon(filled: true, size: 34)
        case .hammer(let h): Image(uiImage: HammerArt.image(h, size: 54, angle: -28, shadow: false))
        }
    }

    private var caption: String {
        switch prize {
        case .coins: return "PARA"
        case .stars: return "YILDIZ"
        case .hammer: return "SÜRPRİZ ÇEKİÇ!"
        }
    }

    private var captionColor: Color {
        switch prize {
        case .coins: return .tkYellow
        case .stars: return .tkYellow
        case .hammer: return .tkGreen
        }
    }

    private var value: String {
        switch prize {
        case .coins(let n): return "+\(n.tk)"
        case .stars(let n): return "+\(n)"
        case .hammer(let h): return h.title
        }
    }
}

/// Tam ekran sandık açma: önce kapalı sandık sallanır, dokununca kapak açılır
/// ve içinden çıkanlar tek tek belirir.
struct ChestOpenView: View {
    let title: String
    let prizes: [ChestPrize]
    var onDone: () -> Void

    @State private var opened = false
    @State private var shown = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.tkDarkest.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture { if !opened { open() } }

            VStack(spacing: 0) {
                DisplayTitle(text: opened ? "SANDIK AÇILDI!" : title, size: 34, depth: 4)
                    .padding(.top, 20)
                    .contentTransition(.opacity)

                Spacer(minLength: 10)

                AnimatedChest(open: opened)
                    .scaleEffect(opened ? 1.0 : (pulse ? 1.04 : 0.97))
                    .onTapGesture { if !opened { open() } }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(opened ? "Açık sandık" : "Sandığı aç")

                if !opened {
                    Text("Açmak için dokun")
                        .font(TKFont.black(18))
                        .foregroundStyle(Color.tkMuted)
                        .opacity(pulse ? 1 : 0.5)
                        .padding(.top, 18)
                }

                VStack(spacing: 10) {
                    ForEach(Array(prizes.enumerated()), id: \.element.id) { i, prize in
                        if i < shown {
                            ChestPrizeTile(prize: prize)
                                .transition(.scale(scale: 0.4).combined(with: .opacity).combined(with: .offset(y: -60)))
                        }
                    }
                }
                .padding(.top, 16)

                Spacer(minLength: 10)

                if opened && shown >= prizes.count {
                    Button(action: onDone) {
                        Text("TOPLA")
                            .font(TKFont.display(32))
                            .frame(height: 66)
                    }
                    .buttonStyle(ChunkyButtonStyle())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .foregroundStyle(Color.tkCream)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func open() {
        Haptics.perfect()
        SoundFX.shared.play(.drive)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { opened = true }
        for i in prizes.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55 + Double(i) * 0.45) {
                SoundFX.shared.play(.coin)
                Haptics.good()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { shown = i + 1 }
            }
        }
    }
}
