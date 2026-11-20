import SwiftUI

struct CoinIcon: View {
    var size: CGFloat = 22

    var body: some View {
        Circle()
            .fill(Color.tkYellow)
            .overlay(Circle().strokeBorder(Color.tkYellowDeep, lineWidth: max(2, size * 0.14)))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct CoinPill: View {
    let text: String
    var iconSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 8) {
            CoinIcon(size: iconSize)
            Text(text)
                .font(TKFont.black(17))
                .foregroundStyle(Color.tkCream)
                .monospacedDigit()
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.tkPanel))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text) para")
    }
}

struct IconSquare: View {
    let systemName: String
    var size: CGFloat = 48

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .heavy))
            .foregroundStyle(Color.tkCream)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkPanel))
    }
}

/// Kalın, alt gölgeli "basılabilir" buton (tasarımdaki OYNA / TEKRAR).
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = .tkYellow
    var shadow: Color = .tkYellowShadow
    var textColor: Color = .tkBg
    var radius: CGFloat = 22
    var depth: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: radius).fill(fill))
            .offset(y: pressed ? depth - 2 : 0)
            .background(RoundedRectangle(cornerRadius: radius).fill(shadow).offset(y: depth))
            .padding(.bottom, depth)
            .animation(.easeOut(duration: 0.06), value: pressed)
            .onChange(of: pressed) { _, isDown in
                if isDown { Haptics.tap() }
            }
    }
}

/// Koyu panel üzerinde basınca hafifçe küçülen buton.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Düz renk gölgeli büyük başlık.
struct DisplayTitle: View {
    let text: String
    var size: CGFloat
    var color: Color = .tkYellow
    var shadow: Color = .tkBrownShadow
    var depth: CGFloat = 6

    var body: some View {
        Text(text)
            .font(TKFont.display(size))
            .foregroundStyle(color)
            .shadow(color: shadow, radius: 0, x: 0, y: depth)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .displayTrim(size)
    }
}

extension View {
    /// Baloo 2'nin satır kutusu çok yüksek (1.6em). Büyük başlıklarda kutuyu harf boyuna indirir;
    /// harfler kutunun dışına taşabildiği için kesilmez.
    func displayTrim(_ size: CGFloat) -> some View {
        frame(height: size * 0.95)
    }
}

/// Ekranın altında kısa süre görünen bilgi mesajı.
struct Toast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(TKFont.black(15))
            .foregroundStyle(Color.tkBg)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.tkCream))
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
