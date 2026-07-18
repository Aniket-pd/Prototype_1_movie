import SwiftUI

struct SyncTableEntryView: View {
    let store: SyncTableStore
    @State private var inviteCode = ""
    @FocusState private var inviteFieldFocused: Bool

    var body: some View {
        ZStack {
            SyncHomeBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    hero
                    startDinnerCard
                    invitationCard
                    howSyncWorks
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SyncHomeTabBar()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("zomato")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(SyncHomePalette.coral)
                HStack(spacing: 7) {
                    Text("Sync Table")
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(SyncHomePalette.coral)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SyncHomePalette.ink.opacity(0.72))
            }
            Spacer()
            Text(store.localParticipant.initials)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [SyncHomePalette.coral, SyncHomePalette.hotPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
                .shadow(color: SyncHomePalette.coral.opacity(0.18), radius: 12, y: 6)
                .accessibilityLabel("Profile, \(store.localParticipant.name)")
        }
    }

    private var hero: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Dinner,")
                        .foregroundStyle(SyncHomePalette.ink)
                    Text("together")
                        .foregroundStyle(SyncHomePalette.coral)
                }
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-1)
                .lineSpacing(-4)
                .padding(.top, 12)
                .zIndex(2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Even when you’re")
                    Text("cities apart.")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SyncHomePalette.ink.opacity(0.88))
                .offset(y: 100)
                .zIndex(2)

                Text("We sync your orders so\nboth meals arrive together.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SyncHomePalette.ink.opacity(0.56))
                    .lineSpacing(4)
                    .offset(y: 151)
                    .zIndex(2)

                Image("SyncDinnerHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * 0.64)
                    .offset(x: width * 0.36, y: 46)
                    .accessibilityLabel("Priya eating noodles and Arjun eating pizza")

                heroPersonLabel(name: "Priya", city: "Mumbai")
                    .offset(x: width * 0.41, y: 202)
                heroPersonLabel(name: "Arjun", city: "Bangalore")
                    .offset(x: width * 0.78, y: 202)


                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(SyncHomePalette.hotPink)
                    .rotationEffect(.degrees(-18))
                    .offset(x: width * 0.72, y: 24)
                    .blur(radius: 0.2)
            }
        }
        .frame(height: 316)
    }

    private func heroPersonLabel(name: String, city: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SyncHomePalette.ink)
            Label(city, systemImage: "mappin")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(SyncHomePalette.ink.opacity(0.65))
                .labelStyle(SyncLocationLabelStyle())
        }
    }

    private var startDinnerCard: some View {
        Button {
            Task { await store.createTable() }
        } label: {
            HStack(spacing: 8) {
                Image("SyncDinnerMugs")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 90)
                    .offset(x: -6)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Sync Dinner")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                    Text("Invite someone and we’ll\nmake both meals arrive\ntogether.")
                        .font(.system(size: 14, weight: .regular))
                        .lineSpacing(3)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(SyncHomePalette.coral)
                    .frame(width: 48, height: 48)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 122)
            .background(
                LinearGradient(
                    colors: [SyncHomePalette.hotPink, Color(red: 1.0, green: 0.58, blue: 0.62)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: SyncHomePalette.coral.opacity(0.15), radius: 18, y: 9)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Creates a new shared meal")
    }

    private var invitationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Already invited?")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(SyncHomePalette.ink)

            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundStyle(SyncHomePalette.ink.opacity(0.43))
                    TextField("Enter invite code", text: $inviteCode)
                        .focused($inviteFieldFocused)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.join)
                        .onSubmit { joinTable() }
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 13)
                .frame(height: 52)
                .background(SyncHomePalette.blush.opacity(0.45), in: RoundedRectangle(cornerRadius: 13))
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(SyncHomePalette.coral.opacity(0.09))
                }

                Button("Join Table") { joinTable() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SyncHomePalette.coral)
                    .frame(width: 100, height: 52)
                    .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 13))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(SyncHomePalette.coral.opacity(0.17))
                    }
                    .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack(spacing: 12) {
                Rectangle().fill(SyncHomePalette.coral.opacity(0.14)).frame(height: 1)
                Text("or")
                    .font(.system(size: 12))
                    .foregroundStyle(SyncHomePalette.ink.opacity(0.56))
                Rectangle().fill(SyncHomePalette.coral.opacity(0.14)).frame(height: 1)
            }

            Button {
                inviteFieldFocused = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.wave.2")
                    Text("Join with invite link")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SyncHomePalette.ink.opacity(0.62))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(.white.opacity(0.85))
        }
        .shadow(color: SyncHomePalette.ink.opacity(0.055), radius: 22, y: 9)
    }

    private var howSyncWorks: some View {
        VStack(spacing: 12) {
            HStack {
                Text("How Sync Works")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncHomePalette.ink)
                Spacer()
                Button("See all") { }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SyncHomePalette.coral)
            }

            HStack(alignment: .top, spacing: 4) {
                SyncStepView(number: 1, symbol: "bag.fill", title: "You order", subtitle: "separately")
                SyncStepConnector()
                SyncStepView(number: 2, symbol: "frying.pan.fill", title: "Restaurants", subtitle: "prepare")
                SyncStepConnector()
                SyncStepView(number: 3, symbol: "scooter", title: "Our AI adjusts", subtitle: "delivery")
                SyncStepConnector()
                SyncStepView(number: 4, symbol: "door.left.hand.closed", title: "Both doors ring", subtitle: "together  ♥")
            }
        }
        .padding(.horizontal, 2)
    }

    private func joinTable() {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            inviteFieldFocused = true
            return
        }
        Task { await store.joinTable(code: code) }
    }
}

private enum SyncHomePalette {
    static let coral = Color(red: 0.94, green: 0.16, blue: 0.27)
    static let hotPink = Color(red: 1.0, green: 0.27, blue: 0.42)
    static let blush = Color(red: 1.0, green: 0.91, blue: 0.92)
    static let ink = Color(red: 0.20, green: 0.06, blue: 0.11)
}

private struct SyncHomeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.96, blue: 0.97),
                Color(red: 1.0, green: 0.985, blue: 0.98),
                Color(red: 1.0, green: 0.96, blue: 0.965)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(SyncHomePalette.hotPink.opacity(0.07))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 90, y: 120)
        }
        .ignoresSafeArea()
    }
}

private struct SyncLocationLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
                .foregroundStyle(SyncHomePalette.hotPink)
            configuration.title
        }
    }
}

private struct SyncStepView: View {
    let number: Int
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .bottomLeading) {
                Circle()
                    .fill(SyncHomePalette.blush.opacity(0.65))
                    .frame(width: 52, height: 52)
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(SyncHomePalette.coral)
                    .frame(width: 52, height: 52)
                Text("\(number)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(SyncHomePalette.hotPink, in: Circle())
                    .offset(x: -2, y: 5)
            }
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(SyncHomePalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(SyncHomePalette.ink.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number), \(title) \(subtitle)")
    }
}

private struct SyncStepConnector: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(SyncHomePalette.coral.opacity(0.24))
                    .frame(width: 2.5, height: 2.5)
            }
        }
        .frame(width: 14)
        .padding(.top, 26)
        .accessibilityHidden(true)
    }
}

private struct MiniParticipantAvatar: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(.white, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

private struct SyncHomeTabBar: View {
    var body: some View {
        HStack(alignment: .bottom) {
            tab(symbol: "magnifyingglass", title: "Discover")
            tab(symbol: "person.2.fill", title: "Sync Table", selected: true)

            VStack(spacing: 3) {
                Text("Z")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [SyncHomePalette.hotPink, SyncHomePalette.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 4))
                    .shadow(color: SyncHomePalette.coral.opacity(0.28), radius: 14, y: 6)
                    .offset(y: -9)
                Color.clear.frame(height: 13)
            }
            .frame(maxWidth: .infinity)

            tab(symbol: "bag.fill", title: "Orders")
            tab(symbol: "person.fill", title: "Profile")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.85)).frame(height: 1)
        }
        .shadow(color: SyncHomePalette.ink.opacity(0.07), radius: 16, y: -5)
    }

    private func tab(symbol: String, title: String, selected: Bool = false) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: selected ? .semibold : .regular))
            Text(title)
                .font(.system(size: 9.5, weight: selected ? .semibold : .regular))
            if selected {
                Circle()
                    .fill(SyncHomePalette.coral)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
            }
        }
        .foregroundStyle(selected ? SyncHomePalette.coral : SyncHomePalette.ink.opacity(0.42))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ConnectionStatusView: View {
    let state: BackendConnectionState

    var body: some View {
        Label(state.title, systemImage: symbol)
            .font(.subheadline.bold())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }

    private var symbol: String {
        switch state {
        case .loading: "arrow.trianglehead.2.clockwise"
        case .disconnected: "wifi.slash"
        case .error: "exclamationmark.triangle.fill"
        case .synced: "checkmark.icloud.fill"
        }
    }

    private var color: Color {
        switch state {
        case .loading: .orange
        case .disconnected, .error: Brand.red
        case .synced: Brand.green
        }
    }
}

struct OrderingModeView: View {
    let store: SyncTableStore

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    orderingHero

                    ForEach(OrderingMode.allCases) { mode in
                        Button {
                            store.selectOrderingMode(mode)
                        } label: {
                            OrderingModeCard(mode: mode, selected: store.table.orderingMode == mode)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        store.go(.matching)
                    } label: {
                        Label("Find restaurants", systemImage: "fork.knife")
                    }
                    .buttonStyle(SyncFlowPrimaryButtonStyle())
                    .disabled(store.table.orderingMode == nil)
                    .opacity(store.table.orderingMode == nil ? 0.58 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var orderingHero: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOW SHOULD TONIGHT WORK?")
                        .font(.system(size: 11.5, weight: .bold))
                        .tracking(1.3)
                        .foregroundStyle(SyncFlowPalette.rose)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Choose an")
                            .foregroundStyle(SyncFlowPalette.ink)
                        HStack(spacing: 6) {
                            Text("ordering")
                                .foregroundStyle(SyncFlowPalette.rose)
                            Text("mode")
                                .foregroundStyle(SyncFlowPalette.ink)
                        }
                    }
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.8)

                    Text("This choice is shared. You can still browse and\nmove between screens independently.")
                        .font(.system(size: 13))
                        .foregroundStyle(SyncFlowPalette.muted)
                        .lineSpacing(5)
                        .padding(.top, 5)
                }
                .frame(width: width * 0.76, alignment: .leading)
                .zIndex(2)

                Image("OrderingModeHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * 0.61)
                    .offset(x: width * 0.48, y: 23)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 250)
    }
}

private struct OrderingModeCard: View {
    let mode: OrderingMode
    let selected: Bool

    var body: some View {
        HStack(spacing: 16) {
            modeArtwork
                .frame(width: 72, height: 72)
                .background(SyncFlowPalette.blush.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(mode.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SyncFlowPalette.ink)
                Text(mode.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(SyncFlowPalette.muted)
                    .lineSpacing(3)
            }

            Spacer()

            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 21))
                .foregroundStyle(selected ? SyncFlowPalette.success : SyncFlowPalette.muted.opacity(0.65))
                .accessibilityHidden(true)
        }
        .syncFlowCard(cornerRadius: 24, padding: 16)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(selected ? SyncFlowPalette.rose.opacity(0.55) : .clear, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var modeArtwork: some View {
        switch mode {
        case .blend:
            Image("MenuDishPaneer")
                .resizable()
                .scaledToFit()
                .padding(6)
        case .sameChain:
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 35))
                    .foregroundStyle(SyncFlowPalette.rose)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(SyncFlowPalette.coral)
                    .background(.white, in: Circle())
            }
        case .differentRestaurants:
            ZStack {
                Image(systemName: "scooter")
                    .font(.system(size: 37))
                    .foregroundStyle(SyncFlowPalette.rose)
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                    .offset(x: 22, y: -21)
            }
        }
    }
}
