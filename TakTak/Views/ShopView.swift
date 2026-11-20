import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var store: GameStore
    var onBack: () -> Void

    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    IconSquare(systemName: "chevron.left")
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Geri")
                Spacer()
                Text("MAĞAZA")
                    .font(TKFont.display(36))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CoinPill(text: store.coins.tk, iconSize: 20)
            }

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(HammerVariant.allCases) { h in
                        hammerCard(h)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .foregroundStyle(Color.tkCream)
        .background(Color.tkBg.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func hammerCard(_ h: HammerVariant) -> some View {
        let isEquipped = store.equipped == h
        let isOwned = store.owned.contains(h)
        let isUnlocked = store.isUnlocked(h)

        Button { select(h) } label: {
            VStack(spacing: 6) {
                Image(uiImage: HammerArt.image(h, size: 92, angle: -28, shadow: true))
                Text(h.title)
                    .font(TKFont.black(16))
                    .foregroundStyle(Color.tkCream)
                HStack(spacing: 6) {
                    if isEquipped {
                        Text("KULLANILIYOR").foregroundStyle(Color.tkYellow)
                    } else if isOwned {
                        Text("SEÇ").foregroundStyle(Color.tkGreen)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                        Text("Rekor \(h.unlockBest ?? 0)")
                    } else if h.price == 0 {
                        Text("ÜCRETSİZ").foregroundStyle(Color.tkGreen)
                    } else {
                        CoinIcon(size: 16)
                        Text(h.price.tk)
                    }
                }
                .font(TKFont.black(14))
                .foregroundStyle(Color.tkCream)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 176)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(isEquipped ? Color.tkYellow : Color.clear, lineWidth: 3))
            .opacity(isUnlocked ? 1 : 0.7)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(h.title)
    }

    private func select(_ h: HammerVariant) {
        switch store.select(h) {
        case .equipped:
            Haptics.tap()
        case .bought:
            Haptics.success()
            SoundFX.shared.play(.coin)
            show("\(h.title) senin!")
        case .notEnough(let missing):
            Haptics.miss()
            show("\(missing.tk) para daha lazım")
        case .locked(let need):
            Haptics.miss()
            show("Açmak için en az \(need) puan yap")
        }
    }

    private func show(_ text: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.3)) { toast = text }
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }
}
