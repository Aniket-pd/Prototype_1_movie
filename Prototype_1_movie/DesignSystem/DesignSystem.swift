import SwiftUI

enum Brand {
    static let red = Color(red: 0.76, green: 0.05, blue: 0.12)
    static let redDark = Color(red: 0.48, green: 0.02, blue: 0.07)
    static let cream = Color(.systemGroupedBackground)
    static let peach = Color(red: 0.98, green: 0.84, blue: 0.73)
    static let green = Color(red: 0.08, green: 0.48, blue: 0.31)
}

struct WarmBackground: View {
    var body: some View {
        LinearGradient(colors: [Brand.cream, Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal)
            .background(Brand.red.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.45)
    }
}

struct SoftCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 7)
    }
}

extension View {
    func softCard() -> some View { modifier(SoftCardModifier()) }
}

struct AvatarView: View {
    let participant: Participant
    var size: Double = 44

    var body: some View {
        Text(participant.initials)
            .font(.body.bold())
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(participant.isHost ? Brand.red : .orange, in: Circle())
            .accessibilityLabel("\(participant.name), \(participant.city)")
    }
}

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.footnote.bold())
                .tracking(1.2)
                .foregroundStyle(Brand.red)
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Int {
    var rupees: String { "₹\(formatted(.number.grouping(.automatic)))" }
}
