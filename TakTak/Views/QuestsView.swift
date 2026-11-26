import SwiftUI

/// Günlük görevler ekranı (tasarımdaki G2).
struct QuestsView: View {
    @EnvironmentObject private var store: GameStore
    var onBack: () -> Void

    @State private var chestReward: GameStore.QuestChestReward?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    IconSquare(systemName: "chevron.left")
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(L("Geri", "Back"))
                Spacer()
                Text(L("GÖREVLER", "QUESTS"))
                    .font(TKFont.display(34))
                    .displayTrim(34)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CoinPill(text: store.coins.tk, iconSize: 20)
            }

            TimelineView(.periodic(from: .now, by: 60)) { context in
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 15, weight: .bold))
                    Text(L("Yeni görevler: ", "New quests in: "))
                        .foregroundColor(.tkMuted)
                    + Text(GameStore.timeUntilTomorrow(from: context.date))
                        .foregroundColor(.tkCream)
                }
                .font(TKFont.black(14))
                .foregroundStyle(Color.tkMuted)
            }
            .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(store.quests) { quest in
                        QuestCard(quest: quest)
                    }
                }
                .padding(.vertical, 16)
            }

            chestCard
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .foregroundStyle(Color.tkCream)
        .background(Color.tkBg.ignoresSafeArea())
        .overlay {
            if let reward = chestReward {
                QuestChestView(reward: reward) {
                    withAnimation(.easeOut(duration: 0.2)) { chestReward = nil }
                }
                .transition(.opacity)
            }
        }
        .onAppear { store.refreshQuestsIfNeeded() }
    }

    private var chestCard: some View {
        HStack(spacing: 14) {
            ChestIcon()
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Görev sandığı", "Quest chest"))
                    .font(TKFont.black(16))
                Text(store.questChestClaimedToday
                     ? L("Toplandı · yarın yeni görevler", "Collected · new quests tomorrow")
                     : L("3 görevi de bitir · \(GameStore.questChestCoins) para + \(GameStore.questChestStars) yıldız", "Finish all 3 · \(GameStore.questChestCoins) coins + \(GameStore.questChestStars) stars"))
                    .font(TKFont.extraBold(13))
                    .foregroundStyle(Color.tkMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i < store.questsClaimedCount ? Color.tkGreen : Color.tkBg)
                            .frame(height: 8)
                    }
                }
                .padding(.top, 4)
            }
            if store.questChestReady {
                Button {
                    if let r = store.openQuestChest() {
                        Haptics.success()
                        SoundFX.shared.play(.coin)
                        withAnimation(.spring(duration: 0.3)) { chestReward = r }
                    }
                } label: {
                    Text(L("AÇ", "OPEN"))
                        .font(TKFont.display(22))
                        .frame(width: 64, height: 44)
                }
                .buttonStyle(ChunkyButtonStyle(radius: 14, depth: 5))
                .frame(width: 64)
                .accessibilityLabel(L("Görev sandığını aç", "Open quest chest"))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(store.questChestReady ? Color.tkYellow : .clear, lineWidth: 3))
        .accessibilityElement(children: .contain)
    }
}

/// Tek görev kartı
struct QuestCard: View {
    @EnvironmentObject private var store: GameStore
    let quest: Quest

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: quest.kind.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(quest.kind.color)
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.tkBg))

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(TKFont.black(16))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        if quest.rewardCoins > 0 {
                            CoinIcon(size: 16)
                            Text("+\(quest.rewardCoins.tk)")
                        }
                        if quest.rewardStars > 0 {
                            StarIcon(filled: true, size: 16)
                            Text(L("+\(quest.rewardStars) yıldız", "+\(quest.rewardStars) stars"))
                        }
                    }
                    .font(TKFont.black(14))
                    .foregroundStyle(Color.tkYellow)
                }
                Spacer(minLength: 0)

                if quest.canClaim {
                    Button {
                        store.claimQuest(quest.id)
                        Haptics.success()
                        SoundFX.shared.play(.coin)
                    } label: {
                        Text(L("AL", "CLAIM"))
                            .font(TKFont.display(22))
                            .frame(width: 72, height: 46)
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: .tkGreen, shadow: .tkGreenShadow, textColor: Color(hex: 0x1C3A2E), radius: 14, depth: 5))
                    .frame(width: 72)
                    .accessibilityLabel(L("Ödülü al: \(quest.title)", "Claim reward: \(quest.title)"))
                } else if quest.claimed {
                    Label(L("ALINDI", "CLAIMED"), systemImage: "checkmark")
                        .font(TKFont.black(13))
                        .foregroundStyle(Color.tkGreen)
                } else if store.canSwapQuest {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { store.swapQuest(quest.id) }
                        Haptics.tap()
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(Color.tkMuted)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.tkBg))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(L("Görevi değiştir (günde bir kez)", "Swap quest (once a day)"))
                }
            }

            HStack(spacing: 10) {
                ProgressBar(fraction: Double(quest.progress) / Double(max(1, quest.goal)),
                            color: quest.isComplete ? .tkGreen : .tkYellow)
                    .frame(height: 12)
                Text("\(quest.progress) / \(quest.goal)")
                    .font(TKFont.black(13))
                    .foregroundStyle(Color.tkMuted)
                    .monospacedDigit()
                    .frame(minWidth: 52, alignment: .trailing)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.tkPanel))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(quest.canClaim ? Color.tkGreen : .clear, lineWidth: 3))
        .opacity(quest.claimed ? 0.7 : 1)
        .accessibilityElement(children: .contain)
    }
}

/// Görev sandığı açılınca çıkan ödül kartı (tasarımdaki G4).
struct QuestChestView: View {
    @EnvironmentObject private var store: GameStore
    let reward: GameStore.QuestChestReward
    var onDone: () -> Void

    @State private var doubled = false
    @State private var loading = false
    @State private var adNotReady = false
    @State private var opened = false
    @State private var revealed = false

    var body: some View {
        ZStack {
            Color.tkDarkest.opacity(0.94)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Label(L("3 / 3 GÖREV", "3 / 3 QUESTS"), systemImage: "checkmark")
                    .font(TKFont.black(13))
                    .tracking(1)
                    .foregroundStyle(Color(hex: 0x1C3A2E))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.tkGreen))

                DisplayTitle(text: L("GÖREV SANDIĞI!", "QUEST CHEST!"), size: 36, depth: 4)
                    .padding(.top, 8)

                AnimatedChest(open: opened)
                    .scaleEffect(revealed ? 0.62 : 0.85)
                    .frame(height: revealed ? 140 : 190)
                    .padding(.top, 4)
                    .onTapGesture { openChest() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(opened ? L("Açık sandık", "Open chest") : L("Sandığı aç", "Open the chest"))

                if !opened {
                    Text(L("Açmak için dokun", "Tap to open"))
                        .font(TKFont.black(17))
                        .foregroundStyle(Color.tkMuted)
                        .padding(.vertical, 14)
                }

                if revealed {
                rewardsBlock
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .padding(EdgeInsets(top: 24, leading: 22, bottom: 22, trailing: 22))
            .foregroundStyle(Color.tkCream)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tkBg))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color.tkPanel, lineWidth: 3))
            .padding(20)
        }
        .alert(L("Reklam hazır değil", "Ad not ready"), isPresented: $adNotReady) {
            Button(L("Tamam", "OK"), role: .cancel) {}
        } message: {
            Text(L("Birkaç saniye sonra tekrar dene.", "Try again in a few seconds."))
        }
    }

    private var multiplierText: String {
        let t = String(format: "%.1f", reward.multiplier)
        return Lang.isTurkish ? t.replacingOccurrences(of: ".", with: ",") : t
    }

    private func openChest() {
        guard !opened else { return }
        Haptics.perfect()
        SoundFX.shared.play(.drive)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { opened = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            SoundFX.shared.play(.coin)
            Haptics.success()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { revealed = true }
        }
    }

    private var rewardsBlock: some View {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    rewardTile(icon: AnyView(CoinIcon(size: 30)), value: "+\((doubled ? reward.coins * 2 : reward.coins).tk)", label: L("para", "coins"))
                    rewardTile(icon: AnyView(StarIcon(filled: true, size: 30)), value: "+\(reward.stars)", label: L("yıldız", "stars"))
                }
                .padding(.top, 6)

                if let h = reward.hammer {
                    HStack(spacing: 12) {
                        Image(uiImage: HammerArt.image(h, size: 64, angle: -28, shadow: false))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("SÜRPRİZ!", "SURPRISE!"))
                                .font(TKFont.black(12))
                                .tracking(1)
                                .foregroundStyle(Color.tkGreen)
                            Text(L("\(h.title) senin", "\(h.title) is yours"))
                                .font(TKFont.black(16))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tkGreen, lineWidth: 3))
                    .padding(.top, 10)
                }

                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.tkOrange)
                    (Text(L("\(reward.streak) günlük görev serisi", "\(reward.streak)-day quest streak")).font(TKFont.black(14))
                     + Text(L(" · ödüller x", " · rewards x") + multiplierText).font(TKFont.extraBold(14)))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x33271F)))
                .padding(.top, 10)

                if !doubled {
                    Button(action: double) {
                        HStack(spacing: 10) {
                            if loading {
                                ProgressView().tint(Color.tkGreen)
                            } else {
                                Image(systemName: store.noAds ? "sparkles" : "play.rectangle.fill")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            Text(store.noAds ? L("Paranı 2 katına çıkar", "Double your coins") : L("Reklam izle, parayı 2 katına çıkar", "Watch an ad to double coins"))
                                .font(TKFont.black(15))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(Color.tkGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tkGreen, lineWidth: 3))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(loading)
                    .padding(.top, 16)
                }

                Button(action: onDone) {
                    Text(L("TOPLA", "COLLECT"))
                        .font(TKFont.display(32))
                        .frame(height: 66)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, doubled ? 18 : 12)

                Text(L("Yarın 3 yeni görev seni bekliyor. Seriyi bozma!", "3 new quests tomorrow. Don't break the streak!"))
                    .font(TKFont.extraBold(13))
                    .foregroundStyle(Color.tkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
    }

    private func double() {
        guard !doubled else { return }
        if store.noAds {
            grantDouble()
            return
        }
        loading = true
        AdsManager.shared.showRewarded { earned in
            loading = false
            if earned { grantDouble() } else { adNotReady = true }
        }
    }

    private func grantDouble() {
        store.addCoins(reward.coins)
        Haptics.success()
        SoundFX.shared.play(.coin)
        withAnimation(.spring(duration: 0.3)) { doubled = true }
    }

    private func rewardTile(icon: AnyView, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            icon
            Text(value)
                .font(TKFont.black(22))
            Text(label)
                .font(TKFont.extraBold(12))
                .foregroundStyle(Color.tkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tkPanel))
        .accessibilityElement(children: .combine)
    }
}

/// Ana menüdeki görev şeridi (tasarımdaki G1).
struct QuestStrip: View {
    @EnvironmentObject private var store: GameStore
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.tkGreen)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.tkBg))
                    .overlay(alignment: .topTrailing) {
                        if store.questsNeedAttention {
                            Circle()
                                .fill(Color.tkRed)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.tkPanel, lineWidth: 3))
                                .offset(x: 4, y: -4)
                        }
                    }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L("Günlük görevler", "Daily quests"))
                            .font(TKFont.black(16))
                        Spacer()
                        Text("\(completedCount) / 3")
                            .font(TKFont.black(14))
                            .foregroundStyle(Color.tkGreen)
                            .monospacedDigit()
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i < completedCount ? Color.tkGreen : Color.tkBg)
                                .frame(height: 8)
                        }
                    }
                    Text(subtitle)
                        .font(TKFont.extraBold(12))
                        .foregroundStyle(Color.tkMuted)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color.tkMuted)
            }
            .foregroundStyle(Color.tkCream)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tkPanel))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.tkGreen, lineWidth: store.questsNeedAttention ? 3 : 0))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(L("Günlük görevler, \(completedCount) / 3 tamam", "Daily quests, \(completedCount) / 3 done"))
    }

    private var completedCount: Int { store.quests.filter(\.isComplete).count }

    private var subtitle: String {
        if store.questChestReady { return L("Görev sandığı hazır!", "Quest chest ready!") }
        if store.quests.contains(where: \.canClaim) { return L("Ödül hazır · yenilenmesine \(GameStore.timeUntilTomorrow())", "Reward ready · resets in \(GameStore.timeUntilTomorrow())") }
        return L("Yenilenmesine \(GameStore.timeUntilTomorrow())", "Resets in \(GameStore.timeUntilTomorrow())")
    }
}

/// Oyun içinde görev bitince üstte beliren kart (tasarımdaki G3).
struct QuestBanner: View {
    let quest: Quest

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: 0x1C3A2E))
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.tkGreen))
            VStack(alignment: .leading, spacing: 0) {
                Text(L("GÖREV TAMAM!", "QUEST DONE!"))
                    .font(TKFont.display(22))
                    .foregroundStyle(Color.tkGreen)
                    .displayTrim(22)
                Text(quest.title)
                    .font(TKFont.extraBold(14))
                    .foregroundStyle(Color(hex: 0xE6F5EE))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if quest.rewardCoins > 0 {
                    CoinIcon(size: 16)
                    Text("+\(quest.rewardCoins)")
                } else {
                    StarIcon(filled: true, size: 16)
                    Text("+\(quest.rewardStars)")
                }
            }
            .font(TKFont.black(15))
            .foregroundStyle(Color.tkYellow)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.tkBg))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: 0x1F4A3A)))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.tkGreen, lineWidth: 3))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
        .rotationEffect(.degrees(-1.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("Görev tamam: \(quest.title)", "Quest done: \(quest.title)"))
    }
}
