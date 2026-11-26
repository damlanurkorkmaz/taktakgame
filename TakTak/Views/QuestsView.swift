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
                .accessibilityLabel("Geri")
                Spacer()
                Text("GÖREVLER")
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
                    Text("Yeni görevler: ")
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
                Text("Görev sandığı")
                    .font(TKFont.black(16))
                Text(store.questChestClaimedToday
                     ? "Toplandı · yarın yeni görevler"
                     : "3 görevi de bitir · \(GameStore.questChestCoins) para + \(GameStore.questChestStars) yıldız")
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
                    Text("AÇ")
                        .font(TKFont.display(22))
                        .frame(width: 64, height: 44)
                }
                .buttonStyle(ChunkyButtonStyle(radius: 14, depth: 5))
                .frame(width: 64)
                .accessibilityLabel("Görev sandığını aç")
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
                            Text("+\(quest.rewardStars) yıldız")
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
                        Text("AL")
                            .font(TKFont.display(22))
                            .frame(width: 72, height: 46)
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: .tkGreen, shadow: .tkGreenShadow, textColor: Color(hex: 0x1C3A2E), radius: 14, depth: 5))
                    .frame(width: 72)
                    .accessibilityLabel("Ödülü al: \(quest.title)")
                } else if quest.claimed {
                    Label("ALINDI", systemImage: "checkmark")
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
                    .accessibilityLabel("Görevi değiştir (günde bir kez)")
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
                Label("3 / 3 GÖREV", systemImage: "checkmark")
                    .font(TKFont.black(13))
                    .tracking(1)
                    .foregroundStyle(Color(hex: 0x1C3A2E))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.tkGreen))

                DisplayTitle(text: "GÖREV SANDIĞI!", size: 36, depth: 4)
                    .padding(.top, 8)

                AnimatedChest(open: opened)
                    .scaleEffect(revealed ? 0.62 : 0.85)
                    .frame(height: revealed ? 140 : 190)
                    .padding(.top, 4)
                    .onTapGesture { openChest() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(opened ? "Açık sandık" : "Sandığı aç")

                if !opened {
                    Text("Açmak için dokun")
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
        .alert("Reklam hazır değil", isPresented: $adNotReady) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Birkaç saniye sonra tekrar dene.")
        }
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
                    rewardTile(icon: AnyView(CoinIcon(size: 30)), value: "+\((doubled ? reward.coins * 2 : reward.coins).tk)", label: "para")
                    rewardTile(icon: AnyView(StarIcon(filled: true, size: 30)), value: "+\(reward.stars)", label: "yıldız")
                }
                .padding(.top, 6)

                if let h = reward.hammer {
                    HStack(spacing: 12) {
                        Image(uiImage: HammerArt.image(h, size: 64, angle: -28, shadow: false))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SÜRPRİZ!")
                                .font(TKFont.black(12))
                                .tracking(1)
                                .foregroundStyle(Color.tkGreen)
                            Text("\(h.title) senin")
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
                    (Text("\(reward.streak) günlük görev serisi").font(TKFont.black(14))
                     + Text(" · ödüller x\(String(format: "%.1f", reward.multiplier).replacingOccurrences(of: ".", with: ","))").font(TKFont.extraBold(14)))
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
                            Text(store.noAds ? "Paranı 2 katına çıkar" : "Reklam izle, parayı 2 katına çıkar")
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
                    Text("TOPLA")
                        .font(TKFont.display(32))
                        .frame(height: 66)
                }
                .buttonStyle(ChunkyButtonStyle())
                .padding(.top, doubled ? 18 : 12)

                Text("Yarın 3 yeni görev seni bekliyor. Seriyi bozma!")
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
                        Text("Günlük görevler")
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
        .accessibilityLabel("Günlük görevler, \(completedCount) / 3 tamam")
    }

    private var completedCount: Int { store.quests.filter(\.isComplete).count }

    private var subtitle: String {
        if store.questChestReady { return "Görev sandığı hazır!" }
        if store.quests.contains(where: \.canClaim) { return "Ödül hazır · yenilenmesine \(GameStore.timeUntilTomorrow())" }
        return "Yenilenmesine \(GameStore.timeUntilTomorrow())"
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
                Text("GÖREV TAMAM!")
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
        .accessibilityLabel("Görev tamam: \(quest.title)")
    }
}
