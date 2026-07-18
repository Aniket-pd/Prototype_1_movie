import SwiftUI

struct WaitingInviteView: View {
    let inviteCode: String
    let createdAt: Date

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("SYNC TABLE CODE")
                    .font(.caption.bold())
                    .tracking(1.1)
                    .foregroundStyle(Brand.red)
                Text(inviteCode)
                    .font(.largeTitle.monospaced().bold())
                    .textSelection(.enabled)
                    .accessibilityLabel("Sync Table code \(inviteCode)")
                InviteExpirationTimer(createdAt: createdAt)
            }

            ShareLink(item: "Join my Zomato Sync Table: zomato.example/sync/\(inviteCode)") {
                Label("Share Invite", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Divider()

            HStack(spacing: 12) {
                ProgressView()
                    .tint(Brand.red)
                Text("Waiting for someone to join…")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Waiting for someone to join")
        }
        .softCard()
    }
}
