import SwiftUI

struct DailyRewardView: View {
    @EnvironmentObject private var store: GameStore
    var onClose: () -> Void

    @State private var bonus: HammerVariant?
    @State private var justClaimed = false

    private let grid = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        let state = store.dailyState
        ZStack {
            Color.tkDarkest.opacity(0.92)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Color.tkMuted)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Kapat")
                }
                .padding(.bottom, -16)

                DisplayTitle(text: "GÜNLÜK ÖDÜL", size: 40, depth: 4)

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("Seri: \(state.day). gün")
                }
                .font(TKFont.black(15))
                .foregroundStyle(Color.tkBg)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.tkOrange))
                .padding(.top, 10)

                LazyVGrid(columns: grid, spacing: 10) {
                    ForEach(1...6, id: \.self) { n in
                        dayCell(n, state: state)
                    }
                }
                .padding(.top, 22)

                dayseven(state: state)
                    .padding(.top, 10)

                Button {
                    let r = store.claimDaily()
                    guard r.coins > 0 else { return }
                    bonus = r.hammer
                    justClaimed = true
                    Haptics.success()
                    SoundFX.shared.play(.coin)
                } label: {
                    Text(state.canClaim ? "AL" : "ALINDI")
                        .font(TKFont.display(36))
                        .frame(height: 68)
                }
                .buttonStyle(ChunkyButtonStyle(
                    fill: state.canClaim ? .tkYellow : .tkGreen,
                    shadow: state.canClaim ? .tkYellowShadow : .tkGreenShadow,
                    radius: 20,
                    depth: 7
                ))
                .disabled(!state.canClaim)
                .padding(.top, 20)

                Text(footer)
                    .font(TKFont.extraBold(14))
                    .foregroundStyle(Color.tkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
            .padding(EdgeInsets(top: 12, leading: 20, bottom: 24, trailing: 20))
            .foregroundStyle(Color.tkCream)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkBg))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tkPanel, lineWidth: 3))
            .padding(20)
        }
        .animation(.spring(duration: 0.3), value: justClaimed)
    }

    private var footer: String {
        if let bonus { return "Sürpriz: \(bonus.title) artık senin!" }
        return "Yarın tekrar gel, seri bozulmasın!"
    }

    @ViewBuilder
    private func dayCell(_ n: Int, state: DailyState) -> some View {
        let done = n < state.day || (n == state.day && !state.canClaim)
        let today = n == state.day

        VStack(spacing: 6) {
            Text("\(n). gün")
                .font(TKFont.extraBold(13))
                .foregroundStyle(Color.tkMuted)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color.tkGreen)
                    .frame(height: 28)
                    .accessibilityLabel("Alındı")
            } else {
                CoinIcon(size: 28)
            }
            Text("\(GameStore.dailyRewards[n - 1])")
                .font(TKFont.black(16))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .background(RoundedRectangle(cornerRadius: 18).fill(today ? Color.tkPanelHi : Color.tkPanel))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(today ? Color.tkYellow : Color.clear, lineWidth: 3))
        .opacity(n > state.day ? 0.75 : 1)
    }

    @ViewBuilder
    private func dayseven(state: DailyState) -> some View {
        let today = state.day == 7
        let done = today && !state.canClaim

        HStack(spacing: 14) {
            Image(systemName: done ? "checkmark.seal.fill" : "shippingbox.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(done ? Color.tkGreen : Color(hex: 0xD99350))
                .frame(width: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("7. GÜN")
                    .font(TKFont.extraBold(13))
                    .foregroundStyle(Color.tkMuted)
                Text("\(GameStore.dailyRewards[6]) + sürpriz çekiç")
                    .font(TKFont.black(17))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 84)
        .background(RoundedRectangle(cornerRadius: 18).fill(today ? Color.tkPanelHi : Color.tkPanel))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(today ? Color.tkYellow : Color.clear, lineWidth: 3))
    }
}
