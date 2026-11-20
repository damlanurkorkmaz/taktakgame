import SwiftUI

/// Yıldız şekli (5 köşeli).
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.48
        var p = Path()
        for i in 0..<10 {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct StarIcon: View {
    var filled: Bool
    var size: CGFloat = 16

    var body: some View {
        StarShape()
            .fill(filled ? Color.tkYellow : Color(hex: 0x4A3628))
            .overlay(StarShape().stroke(Color.tkOutline, style: StrokeStyle(lineWidth: max(1, size * 0.08), lineJoin: .round)))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct LevelMapView: View {
    @EnvironmentObject private var store: GameStore
    var onBack: () -> Void
    var onSelect: (Int) -> Void

    @State private var toast: String?
    private let rowH: CGFloat = 96

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 12)

            GeometryReader { geo in
                let w = geo.size.width
                let total = CGFloat(Level.count) * rowH + 110
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            trail(width: w, total: total)
                            ForEach(Level.all) { level in
                                node(level)
                                    .id(level.number)
                                    .position(point(level.number, width: w, total: total))
                            }
                        }
                        .frame(width: w, height: total)
                    }
                    .onAppear {
                        proxy.scrollTo(store.currentLevel, anchor: .center)
                    }
                }
            }

            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .foregroundStyle(Color.tkCream)
        .background(Color.tkBg.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 180)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Üst kısım

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onBack) {
                    IconSquare(systemName: "chevron.left")
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Ana menü")
                Spacer()
                HStack(spacing: 6) {
                    StarIcon(filled: true, size: 20)
                    Text("\(store.totalStars)")
                        .font(TKFont.black(16))
                        .monospacedDigit()
                }
                .padding(.leading, 10)
                .padding(.trailing, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.tkPanel))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(store.totalStars) yıldız")
                CoinPill(text: store.coins.tk, iconSize: 20)
            }
            VStack(spacing: 0) {
                Text("BÖLÜM 1")
                    .font(TKFont.extraBold(13))
                    .tracking(2)
                    .foregroundStyle(Color.tkMuted)
                DisplayTitle(text: Level.chapterTitle, size: 34, depth: 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Yol ve düğümler

    private func point(_ n: Int, width: CGFloat, total: CGFloat) -> CGPoint {
        let amp = min(100, width * 0.26)
        let x = width / 2 + amp * CGFloat(sin(Double(n - 1) * 1.15))
        let y = total - 70 - CGFloat(n - 1) * rowH
        return CGPoint(x: x, y: y)
    }

    private func trail(width: CGFloat, total: CGFloat) -> some View {
        let current = store.currentLevel
        let done = Path { p in
            for n in 1...current {
                let pt = point(n, width: width, total: total)
                if n == 1 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
        let todo = Path { p in
            for n in current...Level.count {
                let pt = point(n, width: width, total: total)
                if n == current { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
        return ZStack {
            todo.stroke(Color.tkPanelHi, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round, dash: [2, 14]))
            done.stroke(Color(hex: 0xC98A4B), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width, height: total)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func node(_ level: Level) -> some View {
        let n = level.number
        let stars = store.stars(for: n)
        let isCurrent = n == store.unlockedLevel
        let isOpen = store.isLevelOpen(n)

        Button { onSelect(n) } label: {
            VStack(spacing: 6) {
                if isCurrent {
                    Text("\(n)")
                        .font(TKFont.display(34))
                        .foregroundStyle(Color.tkBg)
                        .frame(width: 78, height: 78)
                        .background(Circle().fill(Color.tkYellow))
                        .background(Circle().fill(Color.tkYellowShadow).offset(y: 6))
                        .background(Circle().fill(Color.tkYellow.opacity(0.18)).frame(width: 98, height: 98))
                    capsule(level.isBoss ? "PATRON" : "SIRADAKİ", fill: level.isBoss ? Color(hex: 0xE0503F) : .tkCream,
                            text: level.isBoss ? .tkCream : .tkBg)
                } else if isOpen {
                    Text("\(n)")
                        .font(TKFont.display(26))
                        .foregroundStyle(Color.tkYellow)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(Color.tkPanel))
                        .overlay(Circle().strokeBorder(level.isBoss ? Color(hex: 0xE0503F) : Color(hex: 0xC98A4B), lineWidth: 3))
                        .background(Circle().fill(Color.tkOutline).offset(y: 5))
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { i in
                            StarIcon(filled: i < stars, size: 16)
                        }
                    }
                } else if level.isBoss {
                    VStack(spacing: 0) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("\(n)")
                            .font(TKFont.display(16))
                    }
                    .foregroundStyle(Color.tkRed)
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(Color(hex: 0x5A2A20)))
                    .overlay(Circle().strokeBorder(Color(hex: 0xE0503F), lineWidth: 3))
                    .background(Circle().fill(Color.tkOutline).offset(y: 5))
                    capsule("PATRON", fill: Color(hex: 0xE0503F), text: .tkCream)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8C7A68))
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(Color(hex: 0x33271F)))
                        .overlay(Circle().strokeBorder(Color.tkPanelHi, lineWidth: 3))
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(PressableStyle())
        .disabled(!isOpen)
        .accessibilityLabel(nodeLabel(level, stars: stars, isCurrent: isCurrent, isOpen: isOpen))
    }

    private func capsule(_ text: String, fill: Color, text textColor: Color) -> some View {
        Text(text)
            .font(TKFont.black(11))
            .tracking(1)
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(fill))
    }

    private func nodeLabel(_ level: Level, stars: Int, isCurrent: Bool, isOpen: Bool) -> String {
        var s = "Seviye \(level.number)"
        if level.isBoss { s += ", patron seviyesi" }
        if isCurrent { return s + ", sıradaki" }
        if isOpen { return s + ", \(stars) yıldız" }
        return s + ", kilitli"
    }

    // MARK: - Alt kısım

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ChestIcon()
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Sandık")
                            .font(TKFont.black(14))
                        Spacer()
                        Text("\(min(store.chestProgress, GameStore.chestCost)) / \(GameStore.chestCost)")
                            .font(TKFont.black(14))
                            .foregroundStyle(Color.tkYellow)
                            .monospacedDigit()
                    }
                    ProgressBar(fraction: Double(store.chestProgress) / Double(GameStore.chestCost),
                                color: store.chestReady ? .tkGreen : .tkYellow)
                        .frame(height: 12)
                }
                if store.chestReady {
                    Button(action: openChest) {
                        Text("AÇ")
                            .font(TKFont.display(22))
                            .frame(width: 64, height: 44)
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: .tkGreen, shadow: .tkGreenShadow, radius: 14, depth: 5))
                    .frame(width: 64)
                    .accessibilityLabel("Sandığı aç")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 70)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))

            if store.allLevelsDone {
                Text("Bütün seviyeleri bitirdin! Sonsuz modda rekor kır.")
                    .font(TKFont.extraBold(15))
                    .foregroundStyle(Color.tkMuted)
                    .multilineTextAlignment(.center)
                    .frame(height: 60)
            } else {
                Button { onSelect(store.currentLevel) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .black))
                        Text("SEVİYE \(store.currentLevel)")
                            .font(TKFont.display(34))
                    }
                    .frame(height: 72)
                }
                .buttonStyle(ChunkyButtonStyle())
            }
        }
    }

    private func openChest() {
        let r = store.openChest()
        guard r.coins > 0 else { return }
        Haptics.success()
        SoundFX.shared.play(.coin)
        var text = "Sandıktan \(r.coins) para çıktı!"
        if let h = r.hammer { text += " Bir de \(h.title)!" }
        withAnimation(.spring(duration: 0.3)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }
}

/// Basit dolum çubuğu
struct ProgressBar: View {
    var fraction: Double
    var color: Color = .tkYellow
    var track: Color = .tkBg

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(min(1, max(0, fraction)))))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Tasarımdaki küçük ahşap sandık
struct ChestIcon: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: 0xB97A3C))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(hex: 0x8A5527)).frame(height: 4)
                }
                .frame(width: 44, height: 24)
                .padding(.top, 14)
            UnevenRoundedRectangle(topLeadingRadius: 9, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 9)
                .fill(Color(hex: 0xD99350))
                .frame(width: 48, height: 15)
                .padding(.top, 2)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.tkYellow)
                .frame(width: 10, height: 11)
                .padding(.top, 12)
        }
        .frame(width: 48, height: 40)
        .accessibilityHidden(true)
    }
}
