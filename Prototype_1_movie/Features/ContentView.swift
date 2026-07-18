import SwiftUI

struct ContentView: View {
    let store: SyncTableStore

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.path) {
            ZStack {
                WarmBackground()
                stageView
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if store.stage != .home, store.connectionState != .synced {
                        ConnectionStatusView(state: store.connectionState)
                            .padding(.horizontal, 20)
                    }
                    if let event = store.events.first, Date.now.timeIntervalSince(event.date) < 8 {
                        Label(event.text, systemImage: event.symbol)
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThickMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 8)
            }
            .toolbar {
                if store.stage != .home {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if let previous = AppStage(rawValue: max(0, store.stage.rawValue - 1)) {
                                store.go(previous)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Back")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(store.backendConnected ? Brand.green : Brand.red)
                            .frame(width: 8, height: 8)
                            .accessibilityLabel(store.backendConnected ? "Demo backend connected" : "Demo backend disconnected")
                        Button {
                            store.showDeveloperMenu.toggle()
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Demo controls")
                    }
                }
            }
            .sheet(isPresented: $store.showDeveloperMenu) {
                DeveloperMenu(store: store)
                    .presentationDetents([.medium])
            }
            .alert("Sync Table", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder private var stageView: some View {
        switch store.stage {
        case .home: SyncTableEntryView(store: store)
        case .invite: InviteView(store: store)
        case .modeSelection: OrderingModeView(store: store)
        case .matching: MatchingView(store: store)
        case .menu: SharedMenuView(store: store)
        case .carts: DualCartView(store: store)
        case .payment: PaymentDecisionView(store: store)
        case .checkout: CheckoutView(store: store)
        case .tracking: TrackingView(store: store)
        case .firstBite: FirstBiteView(store: store)
        case .dining: DiningView(store: store)
        case .memory: MemoryView(store: store)
        }
    }
}

struct DeveloperMenu: View {
    let store: SyncTableStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Demo Mode") {
                    Button("Join as Partner") { store.joinPartner() }
                    Button("Partner cart action") { store.simulatePartnerAction() }
                    Button("Set both ready") { store.setBothReady() }
                    Button("Advance delivery") { store.advanceSimulation() }
                    Button("Inject 4-minute delay") { store.injectDelay() }
                    Button("Complete both deliveries") { store.completeDeliveries() }
                    Button("Trigger first-bite countdown") { store.go(.firstBite) }
                }
                Section {
                    Button("Reset entire demo", role: .destructive) {
                        store.reset()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Demo Controls")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

#Preview {
    ContentView(store: SyncTableStore())
}
