import StoreKit
import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var store: GameStore
    @ObservedObject private var iap = StoreManager.shared
    var onBack: () -> Void

    @State private var detail: HammerVariant?
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

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
                    .font(TKFont.display(34))
                    .displayTrim(34)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CoinPill(text: store.coins.tk, iconSize: 20)
            }
            .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    sectionTitle("ÇEKİÇLER", "Her çekicin oyunu değiştiren bir gücü var.")
                    ForEach(HammerVariant.allCases) { h in
                        hammerRow(h)
                    }

                    sectionTitle("GÜÇLENDİRİCİLER", "Seviyeden önce ya da oyun içinde kullan.")
                        .padding(.top, 14)
                    ForEach(Powerup.allCases) { p in
                        powerupRow(p)
                    }

                    sectionTitle("PAKETLER", nil)
                        .padding(.top, 14)
                    packsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .padding(.top, 12)
        .foregroundStyle(Color.tkCream)
        .background(Color.tkBg.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $detail) { h in
            HammerDetailSheet(hammer: h) { result in
                detail = nil
                handle(result, h)
            }
            .environmentObject(store)
            .presentationDetents([.height(620)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.tkBg)
        }
    }

    // MARK: - Bölümler

    private func sectionTitle(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(TKFont.black(14))
                .tracking(1)
            if let subtitle {
                Text(subtitle)
                    .font(TKFont.extraBold(13))
                    .foregroundStyle(Color.tkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func hammerRow(_ h: HammerVariant) -> some View {
        let isEquipped = store.equipped == h
        let isOwned = store.owned.contains(h)
        let isUnlocked = store.isUnlocked(h)

        Button { detail = h } label: {
            HStack(spacing: 12) {
                Image(uiImage: HammerArt.image(h, size: 76, angle: -28, shadow: false))
                    .frame(width: 76, height: 76)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkBg))
                    .opacity(isUnlocked ? 1 : 0.6)
                VStack(alignment: .leading, spacing: 3) {
                    Text(h.title)
                        .font(TKFont.black(16))
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.top, 2)
                        Text(h.power)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(TKFont.extraBold(13))
                    .foregroundStyle(h == .klasik ? Color.tkMuted : Color.tkGreen)
                }
                Spacer(minLength: 4)
                HStack(spacing: 5) {
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
                        CoinIcon(size: 15)
                        Text(h.price.tk)
                    }
                }
                .font(TKFont.black(13))
                .foregroundStyle(Color.tkMuted)
            }
            .foregroundStyle(Color.tkCream)
            .padding(10)
            .padding(.trailing, 4)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(isEquipped ? Color.tkYellow : .clear, lineWidth: 3))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(h.title): \(h.power)")
    }

    private func powerupRow(_ p: Powerup) -> some View {
        HStack(spacing: 12) {
            Image(systemName: p.icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(p.color)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkBg))
            VStack(alignment: .leading, spacing: 2) {
                Text(p.title)
                    .font(TKFont.black(16))
                Text(p.inGameText)
                    .font(TKFont.extraBold(13))
                    .foregroundStyle(Color.tkMuted)
            }
            Spacer(minLength: 4)
            Text("\(store.count(of: p)) adet")
                .font(TKFont.black(13))
                .foregroundStyle(Color.tkGreen)
            Button {
                if store.buyPowerup(p) {
                    Haptics.success()
                    SoundFX.shared.play(.coin)
                } else {
                    Haptics.miss()
                    show("\((p.price - store.coins).tk) para daha lazım")
                }
            } label: {
                HStack(spacing: 4) {
                    CoinIcon(size: 14)
                    Text(p.price.tk)
                }
                .font(TKFont.black(14))
                .frame(width: 76, height: 40)
            }
            .buttonStyle(ChunkyButtonStyle(radius: 12, depth: 4))
            .frame(width: 76)
            .accessibilityLabel("\(p.title) satın al, \(p.price) para")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
    }

    @ViewBuilder
    private var packsSection: some View {
        if iap.products.isEmpty {
            Text(iap.loadFailed ? "Paketler şu an yüklenemedi." : "Paketler yükleniyor…")
                .font(TKFont.extraBold(14))
                .foregroundStyle(Color.tkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
        } else {
            if let noAds = iap.noAdsProduct {
                packRow(product: noAds, icon: "nosign", color: .tkOrange,
                        title: "Reklamsız", subtitle: "Ödülleri reklam izlemeden al",
                        owned: store.noAds)
            }
            ForEach(iap.coinProducts, id: \.id) { product in
                let amount = StoreManager.ProductID.coins(for: product.id)
                packRow(product: product, icon: "circle.hexagongrid.fill", color: .tkYellow,
                        title: "\(amount.tk) para", subtitle: nil, owned: false)
            }
        }
        Button {
            Task {
                await iap.restore()
                show("Satın alımlar geri yüklendi")
            }
        } label: {
            Text("Satın alımları geri yükle")
                .font(TKFont.black(14))
                .foregroundStyle(Color.tkMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(PressableStyle())
    }

    private func packRow(product: Product, icon: String, color: Color, title: String, subtitle: String?, owned: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkBg))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TKFont.black(16))
                if let subtitle {
                    Text(subtitle)
                        .font(TKFont.extraBold(13))
                        .foregroundStyle(Color.tkMuted)
                }
            }
            Spacer(minLength: 4)
            if owned {
                Label("ALINDI", systemImage: "checkmark")
                    .font(TKFont.black(13))
                    .foregroundStyle(Color.tkGreen)
            } else {
                Button {
                    Task {
                        let outcome = await iap.purchase(product)
                        switch outcome {
                        case .success:
                            Haptics.success()
                            SoundFX.shared.play(.coin)
                            show("Teşekkürler!")
                        case .pending:
                            show("Satın alma onay bekliyor")
                        case .failed:
                            show("Satın alma tamamlanamadı")
                        case .cancelled:
                            break
                        }
                    }
                } label: {
                    Group {
                        if iap.purchasing == product.id {
                            ProgressView().tint(Color.tkBg)
                        } else {
                            Text(product.displayPrice)
                        }
                    }
                    .font(TKFont.black(14))
                    .frame(width: 90, height: 40)
                }
                .buttonStyle(ChunkyButtonStyle(fill: .tkGreen, shadow: .tkGreenShadow, textColor: Color(hex: 0x1C3A2E), radius: 12, depth: 4))
                .frame(width: 90)
                .disabled(iap.purchasing != nil)
                .accessibilityLabel("\(title) satın al, \(product.displayPrice)")
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
    }

    // MARK: - İşlemler

    private func handle(_ result: GameStore.SelectResult?, _ h: HammerVariant) {
        guard let result else { return }
        switch result {
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
            show("Açmak için sonsuz modda \(need) puan yap")
        }
    }

    private func show(_ text: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.3)) { toast = text }
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }
}

/// Çekiç detayı (tasarımdaki Ç2): büyük görsel, gücü, satın al / seç.
struct HammerDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    let hammer: HammerVariant
    /// nil: sadece kapatıldı
    var onDone: (GameStore.SelectResult?) -> Void

    var body: some View {
        let isOwned = store.owned.contains(hammer)
        let isEquipped = store.equipped == hammer
        let isUnlocked = store.isUnlocked(hammer)
        let missing = max(0, hammer.price - store.coins)

        VStack(spacing: 0) {
            Image(uiImage: HammerArt.image(hammer, size: 190, angle: -25, shadow: true))
                .frame(width: 200, height: 200)
                .background(Circle().fill(Color.tkPanel))
                .padding(.top, 24)

            DisplayTitle(text: hammer.title, size: 40, depth: 4)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 6) {
                Label("GÜCÜ", systemImage: "bolt.fill")
                    .font(TKFont.black(13))
                    .tracking(1)
                    .foregroundStyle(Color.tkGreen)
                Text(hammer.power)
                    .font(TKFont.black(18))
                    .fixedSize(horizontal: false, vertical: true)
                if hammer.drivesHardInOne {
                    HStack(spacing: 10) {
                        compare(state: .half, title: "Diğer çekiçler", value: "2 vuruş", highlight: false)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Color.tkYellow)
                        compare(state: .driven, title: hammer.title, value: "1 vuruş", highlight: true)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
            .padding(.top, 14)

            Spacer(minLength: 16)

            if isEquipped {
                Text("KULLANILIYOR")
                    .font(TKFont.display(26))
                    .foregroundStyle(Color.tkYellow)
                    .frame(height: 70)
            } else if isOwned || (isUnlocked && hammer.price == 0) {
                Button { onDone(store.select(hammer)) } label: {
                    Text("SEÇ")
                        .font(TKFont.display(32))
                        .frame(height: 70)
                }
                .buttonStyle(ChunkyButtonStyle())
            } else if !isUnlocked {
                Label("Sonsuz modda \(hammer.unlockBest ?? 0) puan yap", systemImage: "lock.fill")
                    .font(TKFont.black(16))
                    .foregroundStyle(Color.tkMuted)
                    .frame(height: 70)
            } else if missing > 0 {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        CoinIcon(size: 18)
                        Text("\(missing.tk) para eksik")
                    }
                    .font(TKFont.black(18))
                    .foregroundStyle(Color.tkMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
                    Text("Görevlerden ve sandıklardan para kazanabilirsin.")
                        .font(TKFont.extraBold(14))
                        .foregroundStyle(Color.tkGreen)
                }
            } else {
                Button { onDone(store.select(hammer)) } label: {
                    HStack(spacing: 12) {
                        Text("SATIN AL")
                            .font(TKFont.display(30))
                        HStack(spacing: 6) {
                            CoinIcon(size: 16)
                            Text(hammer.price.tk)
                        }
                        .font(TKFont.black(18))
                        .foregroundStyle(Color.tkYellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.tkBg))
                    }
                    .frame(height: 70)
                }
                .buttonStyle(ChunkyButtonStyle())
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .foregroundStyle(Color.tkCream)
    }

    private func compare(state: NailState, title: String, value: String, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Image(uiImage: NailArt.image(state, .hard, size: 60))
            Text(title)
                .font(TKFont.extraBold(12))
                .foregroundStyle(Color.tkMuted)
            Text(value)
                .font(TKFont.black(14))
                .foregroundStyle(highlight ? Color.tkGreen : Color.tkCream)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkBg))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(highlight ? Color.tkGreen : .clear, lineWidth: 3))
    }
}
