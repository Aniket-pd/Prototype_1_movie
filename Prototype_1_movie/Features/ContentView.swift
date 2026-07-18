import SwiftUI

struct ContentView: View {
    let store: SyncTableStore

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $store.path) {
            ZStack {
                WarmBackground()
                SyncTableEntryView(store: store)
            }
            .navigationDestination(for: AppStage.self) { stage in
                ZStack {
                    WarmBackground()
                    AppStageView(stage: stage, store: store)
                }
            }
            .toolbar(store.stage == .home ? .hidden : .visible, for: .navigationBar)
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if store.stage != .home, !store.connectionState.isHealthy {
                        ConnectionStatusView(state: store.connectionState)
                            .padding(.horizontal, 20)
                    }
                    if let event = store.transientEvent {
                        Label(event.text, systemImage: event.symbol)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThickMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .padding(.top, 8)
                .allowsHitTesting(false)
            }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(store.connectionState.isHealthy ? Brand.green : Brand.red)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Button("Demo controls", systemImage: "ellipsis.circle") {
                            store.showDeveloperMenu.toggle()
                        }
                        .labelStyle(.iconOnly)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(store.connectionState.title)
                }
                #endif
            }
            .sheet(isPresented: $store.showDeveloperMenu) {
                DeveloperMenu(store: store)
                    .presentationDetents([.medium])
            }
            .alert("Sync Table", isPresented: $store.isShowingError) {
            } message: {
                Text(store.errorMessage)
            }
        }
    }

}

#Preview {
    ContentView(store: SyncTableStore())
}
