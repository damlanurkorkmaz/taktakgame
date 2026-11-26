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
            Text(L("AYARLAR", "SETTINGS"))
                .font(TKFont.display(32))
                .padding(.top, 8)

            toggleRow(L("Ses", "Sound"), icon: "speaker.wave.2.fill", isOn: $store.soundOn)
            toggleRow(L("Müzik", "Music"), icon: "music.note", isOn: $store.musicOn)
            toggleRow(L("Titreşim", "Haptics"), icon: "iphone.radiowaves.left.and.right", isOn: $store.hapticsOn)

            Button {
                Task { await StoreManager.shared.restore() }
                Haptics.tap()
            } label: {
                Label(L("Satın alımları geri yükle", "Restore purchases"), systemImage: "arrow.clockwise")
                    .font(TKFont.black(15))
                    .foregroundStyle(Color.tkMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(PressableStyle())

            HStack(spacing: 10) {
                linkButton(L("Destek", "Support"), icon: "questionmark.circle.fill", url: AppLinks.support)
                linkButton(L("Gizlilik", "Privacy"), icon: "hand.raised.fill", url: AppLinks.privacy)
            }

            Spacer(minLength: 0)

            Text(L("Tak Tak! · Sürüm \(version)", "Tak Tak! · Version \(version)"))
                .font(TKFont.extraBold(13))
                .foregroundStyle(Color.tkMuted)
        }
        .padding(24)
        .foregroundStyle(Color.tkCream)
        .presentationBackground(Color.tkBg)
        .presentationDragIndicator(.visible)
    }

    private func linkButton(_ title: String, icon: String, url: URL) -> some View {
        Link(destination: url) {
            Label(title, systemImage: icon)
                .font(TKFont.black(15))
                .foregroundStyle(Color.tkCream)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkPanel))
        }
        .buttonStyle(PressableStyle())
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
