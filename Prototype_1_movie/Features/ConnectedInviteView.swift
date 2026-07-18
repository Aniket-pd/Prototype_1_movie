import SwiftUI

struct ConnectedInviteView: View {
    let store: SyncTableStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var profilesVisible = false
    @State private var linkVisible = false

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 0) {
                participant(store.table.host, leading: true)

                ZStack {
                    Capsule()
                        .fill(Brand.red.opacity(0.18))
                        .frame(height: 3)
                        .scaleEffect(x: linkVisible ? 1 : 0)
                    Image(systemName: "link")
                        .foregroundStyle(Brand.red)
                        .padding(9)
                        .background(.thinMaterial, in: Circle())
                        .scaleEffect(linkVisible ? 1 : 0.6)
                        .opacity(linkVisible ? 1 : 0)
                }
                .frame(maxWidth: .infinity)

                participant(store.table.partner, leading: false)
            }

            Label("Connected", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(Brand.green)
                .opacity(linkVisible ? 1 : 0)

            if store.table.memory != nil {
                Button("View shared table memory", systemImage: "photo.on.rectangle.angled") {
                    store.openMemory()
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if !store.table.orders.isEmpty {
                Button("Resume live order", systemImage: "location.fill") {
                    store.go(.tracking)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Choose how to order", systemImage: "square.grid.2x2.fill") {
                    store.go(.modeSelection)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .softCard()
        .task {
            await revealConnection()
        }
        .accessibilityElement(children: .contain)
    }

    private func participant(_ participant: Participant, leading: Bool) -> some View {
        VStack(spacing: 8) {
            AvatarView(participant: participant, size: 58)
            Text(participant.name)
                .font(.headline)
            Text(participant.city)
                .font(.caption)
                .foregroundStyle(.secondary)
            Label("Online", systemImage: "checkmark.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(Brand.green)
        }
        .frame(width: 100)
        .opacity(profilesVisible ? 1 : 0)
        .offset(x: profilesVisible ? 0 : (leading ? -24 : 24))
    }

    private func revealConnection() async {
        guard !profilesVisible else { return }
        if reduceMotion {
            profilesVisible = true
            linkVisible = true
            return
        }

        withAnimation(.easeOut(duration: 0.32)) {
            profilesVisible = true
        } completion: {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.72)) {
                linkVisible = true
            }
        }
    }
}
