import SwiftUI

struct ParticipantConfirmationRow: View {
    let participant: Participant
    let isConfirmed: Bool

    var body: some View {
        HStack {
            AvatarView(participant: participant, size: 36)
            Text(participant.name)
            Spacer()
            Label(
                isConfirmed ? "Confirmed" : "Waiting",
                systemImage: isConfirmed ? "checkmark.circle.fill" : "clock"
            )
            .font(.subheadline.bold())
            .foregroundStyle(isConfirmed ? Brand.green : .secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
