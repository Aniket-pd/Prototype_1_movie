import SwiftUI

struct SyncTableEntryView: View {
    let store: SyncTableStore
    @State private var inviteCode = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("zomato")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(Brand.red)
                        Text("Sync Table")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    AvatarView(participant: store.localParticipant)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Eat together,\nwherever you are")
                        .font(.largeTitle.bold())
                    Text("Create a shared table or join one with an invite code. Your restaurant, cart and payment remain yours.")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    Button {
                        Task { await store.createTable() }
                    } label: {
                        EntryActionLabel(
                            symbol: "person.2.badge.plus",
                            title: "Create Sync Table",
                            subtitle: "Start a new shared meal"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(store.connectionState == .loading)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Join Sync Table", systemImage: "link.badge.plus")
                            .font(.title3.bold())
                            .foregroundStyle(Brand.red)
                        TextField("Invite code or link", text: $inviteCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.title3.monospaced())
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                            .accessibilityLabel("Invite code or link")
                        Button("Join with code", systemImage: "arrow.right.circle.fill") {
                            Task { await store.joinTable(code: inviteCode) }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(inviteCode.isEmpty || store.connectionState == .loading)
                    }
                }
                .softCard()

                ConnectionStatusView(state: store.connectionState)

                Text("Two locations. Two carts. One shared meal.")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .navigationBarHidden(true)
    }
}

private struct EntryActionLabel: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Brand.red, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.bold())
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
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
        ScrollView {
            VStack(spacing: 18) {
                SectionHeader(
                    eyebrow: "How should tonight work?",
                    title: "Choose an ordering mode",
                    subtitle: "This choice is shared. You can still browse and move between screens independently."
                )

                ForEach(OrderingMode.allCases) { mode in
                    Button {
                        store.selectOrderingMode(mode)
                    } label: {
                        OrderingModeCard(mode: mode, selected: store.table.orderingMode == mode)
                    }
                    .buttonStyle(.plain)
                }

                Button("Find restaurants", systemImage: "fork.knife") {
                    store.go(.matching)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(store.table.orderingMode == nil)
            }
            .padding(20)
        }
    }
}

private struct OrderingModeCard: View {
    let mode: OrderingMode
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: mode.symbol)
                .font(.title2)
                .foregroundStyle(selected ? .white : Brand.red)
                .frame(width: 48, height: 48)
                .background(selected ? Brand.red : Brand.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(mode.title).font(.headline)
                Text(mode.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Brand.green : .secondary)
                .accessibilityHidden(true)
        }
        .softCard()
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(selected ? Brand.red : .clear, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
