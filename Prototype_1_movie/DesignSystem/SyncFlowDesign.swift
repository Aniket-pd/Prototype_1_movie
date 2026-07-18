import SwiftUI

enum SyncFlowPalette {
    static let coral = Color(red: 0.91, green: 0.06, blue: 0.17)
    static let rose = Color(red: 0.98, green: 0.25, blue: 0.38)
    static let blush = Color(.tertiarySystemFill)
    static let cream = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let ink = Color.primary
    static let muted = Color.secondary
    static let success = Color(red: 0.04, green: 0.57, blue: 0.31)
}

enum SyncFlowLayout {
    static let screenPadding: Double = 20
    static let sectionSpacing: Double = 20
    static let cardRadius: Double = 24
    static let controlHeight: Double = 52
}

struct SyncFlowBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                SyncFlowPalette.cream,
                SyncFlowPalette.cream,
                SyncFlowPalette.rose.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(SyncFlowPalette.rose.opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 58)
                .offset(x: 110, y: 85)
        }
        .ignoresSafeArea()
    }
}

struct SyncFlowCardModifier: ViewModifier {
    var cornerRadius: Double = SyncFlowLayout.cardRadius
    var padding: Double = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SyncFlowPalette.card.opacity(0.92), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.92), lineWidth: 1)
            }
            .shadow(color: SyncFlowPalette.ink.opacity(0.055), radius: 22, y: 10)
    }
}

struct SyncFlowPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal)
            .background(
                LinearGradient(
                    colors: [SyncFlowPalette.coral, SyncFlowPalette.rose],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: SyncFlowPalette.coral.opacity(0.18), radius: 13, y: 7)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

extension View {
    func syncFlowCard(cornerRadius: Double = SyncFlowLayout.cardRadius, padding: Double = 18) -> some View {
        modifier(SyncFlowCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func syncFlowScreenChrome() -> some View {
        background(SyncFlowBackground())
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
