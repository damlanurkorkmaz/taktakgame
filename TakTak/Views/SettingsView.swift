import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: GameStore

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("AYARLAR")
                .font(TKFont.display(32))
                .padding(.top, 8)

            toggleRow("Ses", icon: "speaker.wave.2.fill", isOn: $store.soundOn)
            toggleRow("Titreşim", icon: "iphone.radiowaves.left.and.right", isOn: $store.hapticsOn)

            Spacer(minLength: 0)

            Text("Tak Tak! · Sürüm \(version)")
                .font(TKFont.extraBold(13))
                .foregroundStyle(Color.tkMuted)
        }
        .padding(24)
        .foregroundStyle(Color.tkCream)
        .presentationBackground(Color.tkBg)
        .presentationDragIndicator(.visible)
    }

    private func toggleRow(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: icon)
                .font(TKFont.black(17))
        }
        .tint(Color.tkGreen)
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
    }
}
