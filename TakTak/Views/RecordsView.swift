import SwiftUI

/// Kupa butonu: kendi rekorların + Game Center sıralaması.
struct RecordsView: View {
    @EnvironmentObject private var store: GameStore
    @ObservedObject private var gc = GameCenterManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Text(L("REKORLARIN", "YOUR RECORDS"))
                .font(TKFont.display(32))
                .displayTrim(32)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 4) {
                Text(L("SONSUZ MOD REKORU", "ENDLESS BEST"))
                    .font(TKFont.black(12))
                    .tracking(1.5)
                    .foregroundStyle(Color.tkMuted)
                Text(store.best.tk)
                    .font(TKFont.display(56))
                    .displayTrim(56)
                    .foregroundStyle(Color.tkYellow)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                stat(value: "\(store.levelStars.count)", label: L("seviye geçildi", "levels cleared"))
                stat(value: "\(store.totalStars)", label: L("yıldız", "stars"))
                stat(value: "\(store.levelStars.values.filter { $0 >= 3 }.count)", label: L("3 yıldız", "3 stars"))
            }

            gameCenterSection
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .foregroundStyle(Color.tkCream)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(TKFont.display(28))
                .displayTrim(28)
                .monospacedDigit()
            Text(label)
                .font(TKFont.extraBold(12))
                .foregroundStyle(Color.tkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var gameCenterSection: some View {
        switch gc.status {
        case .signedIn(let name):
            gcButton(title: L("Dünya sıralamasını gör", "View world leaderboard"), icon: "globe.europe.africa.fill") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    GameCenterManager.shared.showLeaderboard()
                }
            }
            note(L("\(name) olarak Game Center'dasın. Rekorların otomatik gönderilir.", "Signed in to Game Center as \(name). Your records are sent automatically."))
        case .needsLogin:
            gcButton(title: L("Game Center'a giriş yap", "Sign in to Game Center"), icon: "person.crop.circle.badge.plus") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    GameCenterManager.shared.presentLogin()
                }
            }
            note(L("Giriş yaparsan rekorların dünya sıralamasına girer.", "Sign in to put your records on the world leaderboard."))
        case .unavailable(let message):
            note(message)
        case .unknown:
            note(L("Game Center'a bağlanılıyor…", "Connecting to Game Center…"))
        }
    }

    private func gcButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                Text(title)
                    .font(TKFont.black(17))
            }
            .frame(height: 60)
        }
        .buttonStyle(ChunkyButtonStyle(fill: .tkGreen, shadow: .tkGreenShadow, textColor: Color(hex: 0x1C3A2E), radius: 18, depth: 5))
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(TKFont.extraBold(14))
            .foregroundStyle(Color.tkMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
    }
}
