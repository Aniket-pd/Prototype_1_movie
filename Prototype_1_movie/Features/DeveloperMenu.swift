import SwiftUI

struct DeveloperMenu: View {
    let store: SyncTableStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Demo Mode") {
                    Button("Join as Partner", action: store.joinPartner)
                    Button("Partner cart action", action: store.simulatePartnerAction)
                    Button("Set both ready", action: store.setBothReady)
                    Button("Advance delivery", action: store.advanceSimulation)
                    Button("Inject 4-minute delay", action: store.injectDelay)
                    Button("Complete both deliveries", action: store.completeDeliveries)
                    Button("Trigger first-bite countdown") {
                        store.go(.firstBite)
                    }
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
