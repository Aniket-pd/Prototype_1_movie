import SwiftUI

struct InviteView: View {
    let store: SyncTableStore

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView {
                VStack(spacing: 22) {
                    inviteHero
                    participantsCard
                    statusCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .syncMotion(value: store.bothConnected)
    }

    private var inviteHero: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("SYNC TABLE  •  \(store.inviteCode)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(SyncFlowPalette.rose)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(store.bothConnected ? "Your table is" : "Waiting for the")
                            .foregroundStyle(SyncFlowPalette.ink)
                        Text(store.bothConnected ? "connected" : "other person")
                            .foregroundStyle(SyncFlowPalette.rose)
                    }
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .tracking(-0.8)

                    Text(
                        store.bothConnected
                            ? "Both locations are online.\nStart when you’re ready."
                            : "Share the code or link below.\nOrdering unlocks after both people join."
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(SyncFlowPalette.muted)
                    .lineSpacing(5)
                    .padding(.top, 7)
                }
                .frame(width: width * 0.62, alignment: .leading)
                .zIndex(2)

                Image("InviteWaitingHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * 0.69)
                    .offset(x: width * 0.38, y: 14)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 205)
    }

    private var participantsCard: some View {
        VStack(spacing: 22) {
            if store.bothConnected {
                connectedParticipants
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            } else {
                pendingParticipants
                    .transition(.opacity)
            }

            // The invite has served its purpose once both people are connected.
            // Removing this whole section also collapses the card instead of leaving a
            // redundant code, expiry timer, or sharing action on screen.
            if !store.bothConnected {
                inviteDetails
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
            }
        }
        .syncFlowCard(cornerRadius: 26, padding: 18)
        .syncMotion(value: store.bothConnected)
    }

    private var inviteDetails: some View {
        VStack(spacing: 22) {
            Divider().overlay(SyncFlowPalette.rose.opacity(0.09))

            VStack(spacing: 7) {
                Text("ST  •  \(store.inviteCode)")
                    .font(.system(size: 25, weight: .bold, design: .monospaced))
                    .foregroundStyle(SyncFlowPalette.ink)
                    .textSelection(.enabled)
                InviteExpirationTimer(createdAt: store.table.createdAt)
            }

            ShareLink(item: "Join my Zomato Sync Table: zomato.example/sync/\(store.inviteCode)") {
                Label("Share Invite", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SyncFlowPalette.rose)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(SyncFlowPalette.blush.opacity(0.74), in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    /// A table is only presented as populated after both ends have confirmed the invite.
    /// This avoids implying that creating an invite has already connected someone.
    private var pendingParticipants: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(SyncFlowPalette.rose)
                .frame(width: 64, height: 64)
                .background(SyncFlowPalette.blush.opacity(0.8), in: Circle())

            Text("Waiting for someone to join")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SyncFlowPalette.ink)
            Text("Share the invite code to connect your table.")
                .font(.system(size: 13))
                .foregroundStyle(SyncFlowPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No users are connected yet. Waiting for someone to join.")
    }

    private var connectedParticipants: some View {
        HStack(alignment: .top, spacing: 0) {
            inviteParticipant(store.localParticipant, local: true)

            ZStack {
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { _ in
                        Capsule()
                            .fill(SyncFlowPalette.success.opacity(0.4))
                            .frame(width: 7, height: 2)
                    }
                }
                Image(systemName: "checkmark")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(SyncFlowPalette.success, in: Circle())
                    .shadow(color: SyncFlowPalette.success.opacity(0.22), radius: 12, y: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 38)

            inviteParticipant(store.remoteParticipant, local: false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync complete. \(store.localParticipant.name) and \(store.remoteParticipant.name) are connected.")
    }

    private func inviteParticipant(_ participant: Participant, local: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Text(participant.initials)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            colors: local
                                ? [SyncFlowPalette.coral, SyncFlowPalette.rose]
                                : [Color.orange.opacity(0.72), Color(red: 1, green: 0.66, blue: 0.48)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                Circle()
                    .fill(SyncFlowPalette.success)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
            }

            Text(participant.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SyncFlowPalette.ink)
            Text(participant.city)
                .font(.system(size: 12))
                .foregroundStyle(SyncFlowPalette.muted)

            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                Text("Synced")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(SyncFlowPalette.success)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                SyncFlowPalette.success.opacity(0.09),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .frame(width: 103)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var statusCard: some View {
        if store.bothConnected {
            Button {
                if store.table.memory != nil {
                    store.openMemory()
                } else if !store.table.orders.isEmpty {
                    store.go(.tracking)
                } else {
                    store.go(.matching)
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Your tablemate is here")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(SyncFlowPrimaryButtonStyle())
        } else {
            HStack(spacing: 15) {
                TablemateWaitingIndicator()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Waiting for your tablemate…")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SyncFlowPalette.rose)
                    Text("Don’t worry, we’ll notify you\nwhen they join!")
                        .font(.system(size: 13))
                        .foregroundStyle(SyncFlowPalette.muted)
                        .lineSpacing(4)
                }
                Spacer()
                ZStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(SyncFlowPalette.rose.opacity(0.72))
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(SyncFlowPalette.blush.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
        }
    }
}

struct MatchingView: View {
    let store: SyncTableStore

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView {
                VStack(spacing: 20) {
                    matchHero

                    if store.isMatching || store.matches.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(SyncFlowPalette.rose)
                            Text("Checking availability • menus • timing")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SyncFlowPalette.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 70)
                        .syncFlowCard()
                    } else {
                        ForEach(store.matches) { pair in
                            MatchCard(
                                pair: pair,
                                selected: store.table.selectedPair?.id == pair.id,
                                selectedByRemoteParticipant: store.selectionWasMadeByRemoteParticipant,
                                hostName: store.table.host.name,
                                partnerName: store.table.partner.name
                            ) {
                                store.select(pair)
                            }
                        }

                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, store.table.selectedPair == nil ? 34 : 96)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.table.selectedPair != nil {
                Button {
                    store.go(.menu)
                } label: {
                    Label("Browse shared menu", systemImage: "fork.knife")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(SyncFlowPalette.rose)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .syncMotion(value: store.table.selectedPair?.id)
        .syncMotion(value: store.isMatching)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            if store.matches.isEmpty {
                await store.findMatches()
            }
        }
    }

    private var matchHero: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Restaurant match".uppercased())
                    .font(.system(size: 11.5, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(SyncFlowPalette.rose)

                VStack(alignment: .leading, spacing: 0) {
                    Text(store.isMatching ? "Finding options" : "Great options")
                    HStack(spacing: 6) {
                        Text("for")
                        Text("both").foregroundStyle(SyncFlowPalette.rose)
                        Text("of you")
                    }
                }
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(SyncFlowPalette.ink)
                .tracking(-0.8)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Image("RestaurantMatchHero")
                .resizable()
                .scaledToFit()
                .frame(width: 118)
                .padding(.trailing, 4)
                .accessibilityHidden(true)
        }
    }
}
struct MatchCard: View {
    let pair: RestaurantPair
    let selected: Bool
    let selectedByRemoteParticipant: Bool
    let hostName: String
    let partnerName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(
                        pair.isSameRestaurant ? "Same restaurant" : "Similar menus",
                        systemImage: pair.isSameRestaurant ? "checkmark.circle.fill" : "arrow.left.arrow.right.circle.fill"
                    )
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(pair.isSameRestaurant ? SyncFlowPalette.success : SyncFlowPalette.rose)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        (pair.isSameRestaurant ? SyncFlowPalette.success : SyncFlowPalette.rose).opacity(0.09),
                        in: Capsule()
                    )
                    Spacer()
                    Text("\(pair.score.total)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(SyncFlowPalette.ink)
                    Text("Sync\nScore")
                        .font(.system(size: 11))
                        .foregroundStyle(SyncFlowPalette.muted)
                }

                Divider().overlay(SyncFlowPalette.rose.opacity(0.08))

                HStack {
                    restaurantName(pair.hostRestaurant, person: hostName, host: true)
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(SyncFlowPalette.rose)
                    restaurantName(pair.partnerRestaurant, person: partnerName, host: false)
                }

                Divider()
                    .overlay(SyncFlowPalette.rose.opacity(0.13))
                    .dashed()

                HStack(spacing: 14) {
                    Image("MenuDishPaneer")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .background(SyncFlowPalette.blush.opacity(0.4), in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 9) {
                        Text(pair.theme)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(SyncFlowPalette.ink)
                            .lineLimit(2)

                        Label("\(pair.score.menuSimilarity)% menu match", systemImage: "checkmark.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SyncFlowPalette.success)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(SyncFlowPalette.success.opacity(0.08), in: Capsule())

                        HStack {
                            Label("Both locations", systemImage: "mappin")
                            Spacer()
                            Label("\(pair.score.predictedDifference) min", systemImage: "clock")
                        }
                        .font(.system(size: 11.5))
                        .foregroundStyle(SyncFlowPalette.muted)
                    }
                }
            }
            .syncFlowCard(cornerRadius: 26, padding: 18)
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        selected
                            ? (selectedByRemoteParticipant ? Color.gray : SyncFlowPalette.rose.opacity(0.5))
                            : .clear,
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pair.theme), Sync Score \(pair.score.total)")
    }

    private func restaurantName(_ restaurant: Restaurant, person: String, host: Bool) -> some View {
        HStack(spacing: 9) {
            if host {
                participantAvatar(host: true)
            }
            VStack(alignment: host ? .leading : .trailing, spacing: 3) {
                Text(person)
                    .font(.system(size: 11))
                    .foregroundStyle(SyncFlowPalette.muted)
                Text(restaurant.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SyncFlowPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(restaurant.city)
                    .font(.system(size: 11))
                    .foregroundStyle(SyncFlowPalette.muted)
            }
            if !host {
                participantAvatar(host: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: host ? .leading : .trailing)
    }

    private func participantAvatar(host: Bool) -> some View {
        Text(host ? "AP" : "AK")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(
                host ? SyncFlowPalette.rose : Color.orange.opacity(0.72),
                in: Circle()
            )
    }
}

private extension View {
    func dashed() -> some View {
        overlay {
            GeometryReader { proxy in
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: proxy.size.width, y: 0))
                }
                .stroke(
                    SyncFlowPalette.rose.opacity(0.16),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 4])
                )
            }
        }
    }
}
