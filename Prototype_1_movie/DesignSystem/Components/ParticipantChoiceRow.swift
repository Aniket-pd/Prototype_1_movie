import SwiftUI

struct ParticipantChoiceRow: View {
    let participant: Participant
    let detail: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(participant: participant)
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Brand.green : .secondary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
