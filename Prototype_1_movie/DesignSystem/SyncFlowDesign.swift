import SwiftUI

enum SyncFlowPalette {
    static let coral = Color(red: 0.91, green: 0.06, blue: 0.17)
    static let rose = Color(red: 0.98, green: 0.25, blue: 0.38)
    static let blush = Color(red: 1.00, green: 0.91, blue: 0.92)
    static let cream = Color(red: 1.00, green: 0.98, blue: 0.96)
    static let ink = Color(red: 0.16, green: 0.055, blue: 0.075)
    static let muted = Color(red: 0.44, green: 0.41, blue: 0.42)
    static let success = Color(red: 0.04, green: 0.57, blue: 0.31)
}

struct SyncFlowBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.97, blue: 0.96),
                Color(red: 1.00, green: 0.985, blue: 0.975),
                Color(red: 1.00, green: 0.955, blue: 0.96)
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
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.92), lineWidth: 1)
            }
            .shadow(color: SyncFlowPalette.ink.opacity(0.055), radius: 22, y: 10)
    }
}

struct SyncFlowPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
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
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

extension View {
    func syncFlowCard(cornerRadius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        modifier(SyncFlowCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func syncFlowScreenChrome() -> some View {
        background(SyncFlowBackground())
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
