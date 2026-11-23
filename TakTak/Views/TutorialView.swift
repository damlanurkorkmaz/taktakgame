import SwiftUI

/// İlk açılışta, 1. seviyeden önce gösterilen 3 adımlık kısa eğitim.
struct TutorialView: View {
    var onDone: () -> Void

    @State private var step = 0
    @State private var pulse = false
    @State private var slide = false

    private let steps = [
        ("Çiviler banttan gelir", "Bant sağdan sola akar, çiviler çekicin altından geçer."),
        ("Oka gelince dokun!", "Çivi sarı okun tam üstüne geldiğinde ekranın herhangi bir yerine dokun."),
        ("Tam ortası = MÜKEMMEL", "Ne kadar tam vurursan o kadar puan. Hiç vurmazsan çivi kaçar ve bir can gider.")
    ]

    var body: some View {
        ZStack {
            Color.tkDarkest.opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("NASIL OYNANIR?")
                        .font(TKFont.black(13))
                        .tracking(2)
                        .foregroundStyle(Color.tkMuted)
                    Spacer()
                    if step < steps.count - 1 {
                        Button("Geç", action: onDone)
                            .font(TKFont.black(15))
                            .foregroundStyle(Color.tkMuted)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }

                illustration
                    .frame(height: 250)
                    .padding(.top, 8)

                DisplayTitle(text: steps[step].0, size: 34, depth: 4)
                    .padding(.top, 12)
                Text(steps[step].1)
                    .font(TKFont.extraBold(17))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                HStack(spacing: 8) {
                    ForEach(steps.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? Color.tkYellow : Color.tkPanel)
                            .frame(width: i == step ? 26 : 10, height: 10)
                    }
                }
                .padding(.top, 22)
                .accessibilityHidden(true)

                Button {
                    if step < steps.count - 1 {
                        withAnimation(.spring(duration: 0.35)) { step += 1 }
                    } else {
                        onDone()
                    }
                } label: {
                    Text(step < steps.count - 1 ? "İLERİ" : "BAŞLA!")
                        .font(TKFont.display(32))
                        .frame(height: 68)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, 22)
            }
            .padding(EdgeInsets(top: 16, leading: 22, bottom: 22, trailing: 22))
            .foregroundStyle(Color.tkCream)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkBg))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tkPanel, lineWidth: 3))
            .padding(20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) { slide = true }
        }
    }

    @ViewBuilder
    private var illustration: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .bottom) {
                switch step {
                case 0:
                    beltImage(width: w, nails: [.init(x: 60, state: .driven), .init(x: 200, state: .up), .init(x: 330, state: .up)])
                    Image(systemName: "arrow.left")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(Color.tkYellow)
                        .offset(x: slide ? -50 : 50, y: -170)
                        .opacity(slide ? 0.2 : 1)
                case 1:
                    beltImage(width: w, nails: [.init(x: 60, state: .driven), .init(x: 195, state: .up), .init(x: 340, state: .up)])
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(Color.tkCream)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
                        .scaleEffect(pulse ? 0.88 : 1.05)
                        .offset(x: 50, y: -150)
                    Text("DOKUN!")
                        .font(TKFont.display(30))
                        .foregroundStyle(Color.tkYellow)
                        .shadow(color: .tkBrownShadow, radius: 0, x: 0, y: 3)
                        .offset(x: -60, y: -185)
                        .opacity(pulse ? 1 : 0.5)
                default:
                    zoneDiagram
                        .padding(.bottom, 20)
                }
            }
            .frame(width: w, height: geo.size.height, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }

    private func beltImage(width: CGFloat, nails: [BeltArt.NailSpot]) -> some View {
        Image(uiImage: BeltArt.sceneImage(width: width, compact: true, nails: nails, nailSize: 80))
    }

    private var zoneDiagram: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                zone("EĞRİ", "+1", Color.tkPanelHi, width: 56)
                zone("İYİ", "+2", Color(hex: 0x7A5A2A), width: 64)
                zone("MÜKEMMEL", "+3 ×seri", Color.tkGreen, width: 100, dark: true)
                zone("İYİ", "+2", Color(hex: 0x7A5A2A), width: 64)
                zone("EĞRİ", "+1", Color.tkPanelHi, width: 56)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            HStack(spacing: 8) {
                Image(systemName: "heart.fill").foregroundStyle(Color.tkRed)
                Image(systemName: "heart.fill").foregroundStyle(Color.tkRed)
                Image(systemName: "heart.fill").foregroundStyle(Color.tkRed)
                Text("3 can")
                    .font(TKFont.black(15))
                    .foregroundStyle(Color.tkMuted)
            }
            .font(.system(size: 22, weight: .bold))
        }
    }

    private func zone(_ title: String, _ points: String, _ color: Color, width: CGFloat, dark: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(TKFont.black(11))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(points)
                .font(TKFont.black(12))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(dark ? Color(hex: 0x1C3A2E) : Color.tkCream)
        .frame(width: width, height: 76)
        .background(color)
    }
}
