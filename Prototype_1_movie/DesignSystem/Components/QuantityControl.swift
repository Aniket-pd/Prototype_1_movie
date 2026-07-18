import SwiftUI

struct QuantityControl: View {
    let itemName: String
    let quantity: Int
    let add: () -> Void
    let remove: () -> Void

    var body: some View {
        if quantity > 0 {
            HStack(spacing: 10) {
                Button("Remove \(itemName)", systemImage: "minus", action: remove)
                    .labelStyle(.iconOnly)
                Text(quantity, format: .number)
                    .font(.subheadline.bold().monospacedDigit())
                    .contentTransition(.numericText())
                Button("Add \(itemName)", systemImage: "plus", action: add)
                    .labelStyle(.iconOnly)
            }
            .foregroundStyle(SyncFlowPalette.rose)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(SyncFlowPalette.blush.opacity(0.85), in: Capsule())
        } else {
            Button("Add \(itemName)", systemImage: "plus", action: add)
                .labelStyle(.iconOnly)
                .font(.headline)
                .foregroundStyle(SyncFlowPalette.rose)
                .frame(width: 44, height: 44)
                .background(SyncFlowPalette.blush.opacity(0.9), in: Circle())
        }
    }
}
