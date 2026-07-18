import SwiftUI

struct AppStageView: View {
    let stage: AppStage
    let store: SyncTableStore

    var body: some View {
        switch stage {
        case .home:
            SyncTableEntryView(store: store)
        case .invite:
            InviteView(store: store)
        case .matching:
            MatchingView(store: store)
        case .menu:
            SharedMenuView(store: store)
        case .carts:
            DualCartView(store: store)
        case .payment:
            PaymentDecisionView(store: store)
        case .checkout:
            CheckoutView(store: store)
        case .tracking:
            TrackingView(store: store)
        case .firstBite:
            FirstBiteView(store: store)
        case .dining:
            DiningView(store: store)
        case .memory:
            MemoryView(store: store)
        }
    }
}
