import SwiftUI

struct InviteExpirationTimer: View {
    let createdAt: Date

    private var expirationDate: Date {
        createdAt.addingTimeInterval(15 * 60)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(expirationDate.timeIntervalSince(context.date)))
            Label(
                remaining == 0 ? "Invite expired" : "Invite expires in \(formatted(remaining))",
                systemImage: remaining == 0 ? "clock.badge.exclamationmark" : "clock"
            )
            .font(.subheadline)
            .foregroundStyle(remaining == 0 ? Brand.red : .secondary)
            .monospacedDigit()
            .contentTransition(.numericText())
            .accessibilityLabel(
                remaining == 0
                    ? "Invite expired"
                    : "Invite expires in \(remaining / 60) minutes and \(remaining % 60) seconds"
            )
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
