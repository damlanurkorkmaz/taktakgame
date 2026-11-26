import StoreKit
import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var store: GameStore
    @ObservedObject private var iap = StoreManager.shared
    var onBack: () -> Void

    @State private var detail: HammerVariant?
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var celebration: PurchaseCelebration.Item?
    @State private var celebrationTask: Task<Void, Never>?
    @State private var celebrationKey = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    IconSquare(systemName: "chevron.left")
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(L("Geri", "Back"))
                Spacer()
                Text(L("MAĞAZA", "SHOP"))
                    .font(TKFont.display(34))
                    .displayTrim(34)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CoinPill(text: store.coins.tk, iconSize: 20)
            }
            .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    sectionTitle(L("ÇEKİÇLER", "HAMMERS"), L("Her çekicin oyunu değiştiren bir gücü var.", "Every hammer has a game-changing power."))
                    ForEach(HammerVariant.allCases) { h in
                        hammerRow(h)
                    }

                    sectionTitle(L("GÜÇLENDİRİCİLER", "POWER-UPS"), L("Seviyeden önce ya da oyun içinde kullan.", "Use them before a level or during play."))
                        .padding(.top, 14)
                    ForEach(Powerup.allCases) { p in
                        powerupRow(p)
                    }

                    sectionTitle(L("PAKETLER", "PACKS"), nil)
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
        .overlay {
            if let item = celebration {
                PurchaseCelebration(item: item) { dismissCelebration() }
                    .id(celebrationKey)
                    .transition(.opacity)
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
                        Text(L("KULLANILIYOR", "EQUIPPED")).foregroundStyle(Color.tkYellow)
                    } else if isOwned {
                        Text(L("SEÇ", "EQUIP")).foregroundStyle(Color.tkGreen)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                        Text(L("Rekor \(h.unlockBest ?? 0)", "Best \(h.unlockBest ?? 0)"))
                    } else if h.price == 0 {
                        Text(L("ÜCRETSİZ", "FREE")).foregroundStyle(Color.tkGreen)
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
            Text(L("\(store.count(of: p)) adet", "×\(store.count(of: p))"))
                .font(TKFont.black(13))
                .foregroundStyle(Color.tkGreen)
            Button {
                if store.buyPowerup(p) {
                    celebrate(.powerup(p))
                } else {
                    Haptics.miss()
                    show(L("\((p.price - store.coins).tk) para daha lazım", "You need \((p.price - store.coins).tk) more coins"))
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
            .accessibilityLabel(L("\(p.title) satın al, \(p.price) para", "Buy \(p.title), \(p.price) coins"))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
    }

    @ViewBuilder
    private var packsSection: some View {
        if iap.products.isEmpty {
            Text(iap.loadFailed ? L("Paketler şu an yüklenemedi.", "Packs couldn't be loaded right now.") : L("Paketler yükleniyor…", "Loading packs…"))
                .font(TKFont.extraBold(14))
                .foregroundStyle(Color.tkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
        } else {
            if let noAds = iap.noAdsProduct {
                packRow(product: noAds, icon: "nosign", color: .tkOrange,
                        title: L("Reklamsız", "No Ads"), subtitle: L("Ödülleri reklam izlemeden al", "Get rewards without watching ads"),
                        owned: store.noAds)
            }
            ForEach(iap.coinProducts, id: \.id) { product in
                let amount = StoreManager.ProductID.coins(for: product.id)
                packRow(product: product, icon: "circle.hexagongrid.fill", color: .tkYellow,
                        title: L("\(amount.tk) para", "\(amount.tk) coins"), subtitle: nil, owned: false)
            }
        }
        Button {
            Task {
                await iap.restore()
                show(L("Satın alımlar geri yüklendi", "Purchases restored"))
            }
        } label: {
            Text(L("Satın alımları geri yükle", "Restore purchases"))
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
                Label(L("ALINDI", "OWNED"), systemImage: "checkmark")
                    .font(TKFont.black(13))
                    .foregroundStyle(Color.tkGreen)
            } else {
                Button {
                    Task {
                        let outcome = await iap.purchase(product)
                        switch outcome {
                        case .success:
                            if product.id == StoreManager.ProductID.noAds {
                                celebrate(.noAds)
                            } else {
                                celebrate(.coins(StoreManager.ProductID.coins(for: product.id)))
                            }
                        case .pending:
                            show(L("Satın alma onay bekliyor", "Purchase is awaiting approval"))
                        case .failed:
                            show(L("Satın alma tamamlanamadı", "Purchase couldn't be completed"))
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
                .accessibilityLabel(L("\(title) satın al, \(product.displayPrice)", "Buy \(title), \(product.displayPrice)"))
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
            // Detay sayfası kapanırken üst üste binmesin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { celebrate(.hammer(h)) }
        case .notEnough(let missing):
            Haptics.miss()
            show(L("\(missing.tk) para daha lazım", "You need \(missing.tk) more coins"))
        case .locked(let need):
            Haptics.miss()
            show(L("Açmak için sonsuz modda \(need) puan yap", "Score \(need) in Endless to unlock"))
        }
    }

    private func celebrate(_ item: PurchaseCelebration.Item) {
        Haptics.success()
        SoundFX.shared.play(.coin)
        celebrationTask?.cancel()
        celebrationKey += 1
        withAnimation(.easeOut(duration: 0.15)) { celebration = item }
        celebrationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            dismissCelebration()
        }
    }

    private func dismissCelebration() {
        celebrationTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) { celebration = nil }
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
                Label(L("GÜCÜ", "POWER"), systemImage: "bolt.fill")
                    .font(TKFont.black(13))
                    .tracking(1)
                    .foregroundStyle(Color.tkGreen)
                Text(hammer.power)
                    .font(TKFont.black(18))
                    .fixedSize(horizontal: false, vertical: true)
                if hammer.drivesHardInOne {
                    HStack(spacing: 10) {
                        compare(state: .half, title: L("Diğer çekiçler", "Other hammers"), value: L("2 vuruş", "2 hits"), highlight: false)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Color.tkYellow)
                        compare(state: .driven, title: hammer.title, value: L("1 vuruş", "1 hit"), highlight: true)
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
                Text(L("KULLANILIYOR", "EQUIPPED"))
                    .font(TKFont.display(26))
                    .foregroundStyle(Color.tkYellow)
                    .frame(height: 70)
            } else if isOwned || (isUnlocked && hammer.price == 0) {
                Button { onDone(store.select(hammer)) } label: {
                    Text(L("SEÇ", "EQUIP"))
                        .font(TKFont.display(32))
                        .frame(height: 70)
                }
                .buttonStyle(ChunkyButtonStyle())
            } else if !isUnlocked {
                Label(L("Sonsuz modda \(hammer.unlockBest ?? 0) puan yap", "Score \(hammer.unlockBest ?? 0) in Endless"), systemImage: "lock.fill")
                    .font(TKFont.black(16))
                    .foregroundStyle(Color.tkMuted)
                    .frame(height: 70)
            } else if missing > 0 {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        CoinIcon(size: 18)
                        Text(L("\(missing.tk) para eksik", "\(missing.tk) coins short"))
                    }
                    .font(TKFont.black(18))
                    .foregroundStyle(Color.tkMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
                    Text(L("Görevlerden ve sandıklardan para kazanabilirsin.", "Earn coins from quests and chests."))
                        .font(TKFont.extraBold(14))
                        .foregroundStyle(Color.tkGreen)
                }
            } else {
                Button { onDone(store.select(hammer)) } label: {
                    HStack(spacing: 12) {
                        Text(L("SATIN AL", "BUY"))
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

/// Satın alınca ekranın ortasında beliren L("ALINDI!", "GOT IT!") kartı.
struct PurchaseCelebration: View {
    enum Item: Hashable {
        case hammer(HammerVariant)
        case powerup(Powerup)
        case coins(Int)
        case noAds
    }

    let item: Item
    var onTap: () -> Void

    @State private var appear = false
    @State private var burst = false

    var body: some View {
        ZStack {
            Color.tkDarkest.opacity(appear ? 0.7 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: onTap)

            ZStack {
                // Etrafa saçılan paralar/yıldızlar
                ForEach(0..<14, id: \.self) { i in
                    let a = Double(i) / 14 * 2 * .pi
                    let r: Double = 130 + Double(i % 3) * 18
                    Group {
                        if i.isMultiple(of: 2) { CoinIcon(size: 20) } else { StarIcon(filled: true, size: 18) }
                    }
                    .offset(x: burst ? cos(a) * r : 0, y: burst ? sin(a) * r : 0)
                    .opacity(burst ? 0 : 1)
                    .scaleEffect(burst ? 1.1 : 0.4)
                }

                VStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(hex: 0x1C3A2E))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.tkGreen))
                        .overlay(Circle().strokeBorder(Color.tkOutline, lineWidth: 3))

                    icon
                        .frame(height: 110)

                    DisplayTitle(text: L("ALINDI!", "GOT IT!"), size: 40, depth: 4)

                    Text(subtitle)
                        .font(TKFont.black(17))
                        .multilineTextAlignment(.center)
                    Text(detail)
                        .font(TKFont.extraBold(14))
                        .foregroundStyle(Color.tkMuted)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Color.tkCream)
                .padding(.horizontal, 26)
                .padding(.vertical, 22)
                .frame(maxWidth: 300)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkBg))
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tkGreen, lineWidth: 4))
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)
            }
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("Satın alındı. \(subtitle)", "Purchased. \(subtitle)"))
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) { appear = true }
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) { burst = true }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .hammer(let h):
            Image(uiImage: HammerArt.image(h, size: 110, angle: -28, shadow: false))
        case .powerup(let p):
            Image(systemName: p.icon)
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(p.color)
                .frame(width: 100, height: 100)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkPanel))
        case .coins:
            HStack(spacing: -18) {
                CoinIcon(size: 56).offset(y: 10)
                CoinIcon(size: 70)
                CoinIcon(size: 56).offset(y: 10)
            }
        case .noAds:
            Image(systemName: "nosign")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(Color.tkOrange)
                .frame(width: 100, height: 100)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkPanel))
        }
    }

    private var subtitle: String {
        switch item {
        case .hammer(let h): return L("\(h.title) senin!", "\(h.title) is yours!")
        case .powerup(let p): return "+1 \(p.title)"
        case .coins(let n): return L("+\(n.tk) para", "+\(n.tk) coins")
        case .noAds: return L("Reklamlar kapandı", "Ads removed")
        }
    }

    private var detail: String {
        switch item {
        case .hammer: return L("Takılı çekicin oldu. Hemen dene!", "It's now equipped. Try it out!")
        case .powerup: return L("Seviyeden önce ya da oyun içinde kullanabilirsin.", "Use it before a level or during play.")
        case .coins: return L("Paran hesabına eklendi. Teşekkürler!", "Coins added to your balance. Thank you!")
        case .noAds: return L("Ödülleri artık reklam izlemeden alırsın. Teşekkürler!", "You now get rewards without watching ads. Thank you!")
        }
    }
}
