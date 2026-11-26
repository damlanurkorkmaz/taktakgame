import SwiftUI

/// Rekor kırınca paylaşılan görsel (1080x1350, Instagram dikey formatı).
struct ShareCardView: View {
    let score: Int
    let hammer: HammerVariant

    var body: some View {
        VStack(spacing: 0) {
            Text("TAK TAK!")
                .font(TKFont.display(120))
                .foregroundStyle(Color.tkYellow)
                .shadow(color: .tkBrownShadow, radius: 0, x: 0, y: 10)
                .frame(height: 130)
                .padding(.top, 90)

            Text(L("YENİ REKOR", "NEW RECORD"))
                .font(TKFont.black(40))
                .tracking(4)
                .foregroundStyle(Color(hex: 0x1C3A2E))
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.tkGreen))
                .padding(.top, 50)

            Text("\(score)")
                .font(TKFont.display(300))
                .foregroundStyle(Color.tkCream)
                .shadow(color: .tkOutline, radius: 0, x: 0, y: 14)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(height: 300)
                .padding(.top, 20)

            ZStack(alignment: .bottom) {
                Image(uiImage: BeltArt.sceneImage(
                    width: 1080, compact: true,
                    nails: [.init(x: 70, state: .driven), .init(x: 205, state: .up), .init(x: 340, state: .driven)],
                    nailSize: 190))
                Image(uiImage: HammerArt.image(hammer, size: 520, angle: -35, shadow: false))
                    .offset(x: 140, y: -170)
            }
            .frame(height: 420)

            Spacer(minLength: 0)

            Text(L("Beni geçebilir misin?", "Can you beat me?"))
                .font(TKFont.black(52))
                .foregroundStyle(Color.tkMuted)
                .padding(.bottom, 90)
        }
        .frame(width: 1080, height: 1350)
        .background(Color.tkBg)
    }
}

enum ShareCard {
    @MainActor
    static func image(score: Int, hammer: HammerVariant) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(score: score, hammer: hammer))
        renderer.scale = 1
        return renderer.uiImage
    }
}
