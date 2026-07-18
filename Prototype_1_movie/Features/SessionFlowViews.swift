import SwiftUI

struct SyncTableEntryView: View {
    let store: SyncTableStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var inviteCode = ""
    @State private var isJoinExpanded = false
    @FocusState private var inviteFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                hero
                startDinnerCard
                invitationCard
                howSyncWorks
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .tint(SyncHomePalette.coral)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("zomato")
                    .font(.headline.weight(.bold))
                    .italic()
                    .foregroundStyle(SyncHomePalette.coral)
                Text("Sync Table")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Profile, \(store.localParticipant.name)")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dinner, together")
                .font(.largeTitle.bold())

            Text("Order separately, then let us coordinate delivery so you can share the moment.")
                .font(.body)
                .foregroundStyle(.secondary)

            Image("SyncDinnerHero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 180 : 150)
                .accessibilityLabel("Two friends sharing dinner from different cities")
        }
    }

    private var startDinnerCard: some View {
        Button {
            Task { await store.createTable() }
        } label: {
            Label("Start a Sync Table", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(store.isSubmitting)
        .accessibilityHint("Create a table and invite someone to join")
    }

    private var invitationCard: some View {
        DisclosureGroup(isExpanded: $isJoinExpanded) {
            VStack(spacing: 12) {
                inviteCodeField
                joinButton
            }
            .padding(.top, 12)
        } label: {
            Label("Join an invite", systemImage: "link")
                .font(.headline)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var inviteCodeField: some View {
        HStack(spacing: 10) {
            Image(systemName: "qrcode.viewfinder")
                .foregroundStyle(.secondary)
            TextField("Invite code", text: $inviteCode)
                .focused($inviteFieldFocused)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.join)
                .onSubmit(joinTable)
                .font(.body)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: SyncFlowLayout.controlHeight)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(.separator).opacity(0.35)))
    }

    private var joinButton: some View {
        Button("Join Table", action: joinTable)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .disabled(
                inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || store.isSubmitting
            )
    }

    private var howSyncWorks: some View {
        DisclosureGroup("How Sync Table works") {
            Text("Choose your own restaurants and meals. We coordinate preparation and delivery timing so both orders arrive together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .font(.subheadline.weight(.semibold))
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
    static let blush = Color(.tertiarySystemFill)
    static let ink = Color.primary
}

private enum SyncHomeLayout {
    static let screenPadding: Double = 16
}

private struct SyncHomeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground),
                SyncHomePalette.hotPink.opacity(0.08)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(SyncHomePalette.coral)
                    .frame(width: 52, height: 52)
                    .background(SyncHomePalette.blush.opacity(0.65), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(number): \(title)")
                        .font(.headline)
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 7) {
                ZStack(alignment: .bottomLeading) {
                    Circle()
                        .fill(SyncHomePalette.blush.opacity(0.65))
                        .frame(width: 46, height: 46)
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SyncHomePalette.coral)
                        .frame(width: 46, height: 46)
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(SyncHomePalette.hotPink, in: Circle())
                        .offset(x: -2, y: 5)
                }
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(SyncHomePalette.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 82)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Step \(number), \(title) \(subtitle)")
        }
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
        .padding(.top, 23)
        .accessibilityHidden(true)
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
        case .local: "iphone"
        case .disconnected: "wifi.slash"
        case .error: "exclamationmark.triangle.fill"
        case .synced: "checkmark.icloud.fill"
        }
    }

    private var color: Color {
        switch state {
        case .loading: .orange
        case .local: Brand.green
        case .disconnected, .error: Brand.red
        case .synced: Brand.green
        }
    }
}
