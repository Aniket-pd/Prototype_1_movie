import SwiftUI

@main
struct SyncTableApp: App {
    @State private var store = SyncTableStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .tint(Brand.red)
                .preferredColorScheme(nil)
                .task { await store.connectToDemoBackend() }
        }
    }
}
#Preview {
    ContentView(store: SyncTableStore())
        .tint(Brand.red)
}
