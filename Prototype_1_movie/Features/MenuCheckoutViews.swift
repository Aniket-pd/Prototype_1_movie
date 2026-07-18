import SwiftUI

struct SharedMenuView: View {
    let store: SyncTableStore
    @State private var viewingOther = false

    private var pair: RestaurantPair? { store.table.selectedPair }
    private var menu: [MenuItem] {
        viewingOther ? (store.remoteRestaurant?.menu ?? []) : (store.localRestaurant?.menu ?? [])
    }

    var body: some View {
        ZStack {
            SyncFlowBackground()

            ScrollView {
                LazyVStack(spacing: 14) {
                    menuContext

                    Label(
                        store.events.first?.text ?? "\(store.remoteParticipant.name) joined from \(store.remoteParticipant.city)",
                        systemImage: store.events.first?.symbol ?? "person.2.fill"
                    )
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(SyncFlowPalette.rose)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15)
                    .frame(height: 52)
                    .background(SyncFlowPalette.blush.opacity(0.6), in: RoundedRectangle(cornerRadius: 17))

                    ForEach(menu) { item in
                        MenuItemCard(
                            item: item,
                            counterpart: counterpart(for: item),
                            editable: !viewingOther,
                            quantity: store.localCart.items.first(where: { $0.menuItem.id == item.id })?.quantity ?? 0,
                            add: { store.addLocalItem(item) },
                            remove: { store.removeLocalItem(item) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Choose dinner")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            Button {
                store.go(.carts)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "basket.fill")
                    Text("View both carts")
                    Spacer()
                    Text("\(store.localCart.itemCount) items • \(store.localCart.total.rupees)")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(SyncFlowPrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .task {
            if store.backendConnected == false && store.table.partnerCart.items.isEmpty {
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { return }
                store.simulatePartnerAction()
            }
        }
        .sensoryFeedback(.selection, trigger: store.localCart.itemCount)
    }

    private var menuContext: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text((pair?.theme ?? "Shared menu").uppercased())
                .font(.system(size: 11.5, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(SyncFlowPalette.rose)

            Text("You can see \(store.remoteParticipant.name)’s cart, but only they can change it.")
                .font(.system(size: 13))
                .foregroundStyle(SyncFlowPalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Whose local menu", selection: $viewingOther) {
                Text("Your menu • \(store.localParticipant.city)").tag(false)
                Text("\(store.remoteParticipant.name) • \(store.remoteParticipant.city)").tag(true)
            }
            .pickerStyle(.segmented)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func counterpart(for item: MenuItem) -> MenuItem? {
        guard let otherMenu = store.remoteRestaurant?.menu else { return nil }
        return otherMenu.max { lhs, rhs in
            item.tags.intersection(lhs.tags).count < item.tags.intersection(rhs.tags).count
        }
    }
}

struct MenuItemCard: View {
    let item: MenuItem
    let counterpart: MenuItem?
    let editable: Bool
    let quantity: Int
    let add: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(dishAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 112)
                .background(SyncFlowPalette.blush.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Image(systemName: item.isVegetarian ? "leaf.fill" : "circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(item.isVegetarian ? SyncFlowPalette.success : SyncFlowPalette.rose)
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SyncFlowPalette.ink)
                        .lineLimit(2)
                }
                Text(item.description)
                    .font(.system(size: 11.5))
                    .foregroundStyle(SyncFlowPalette.muted)
                    .lineLimit(2)
                    .lineSpacing(2)

                if let counterpart {
                    Label("Twin: \(counterpart.name)", systemImage: "arrow.left.arrow.right")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(SyncFlowPalette.rose)
                        .lineLimit(1)
                }

                HStack {
                    Text(item.price.rupees)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SyncFlowPalette.ink)
                    Spacer()
                    if editable {
                        QuantityControl(
                            itemName: item.name,
                            quantity: quantity,
                            add: add,
                            remove: remove
                        )
                    } else {
                        Label("View only", systemImage: "eye")
                            .font(.system(size: 10.5))
                            .foregroundStyle(SyncFlowPalette.muted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .syncFlowCard(cornerRadius: 23, padding: 14)
    }

    private var dishAsset: String {
        let name = item.name.lowercased()
        if name.contains("paneer") || name.contains("tandoori") {
            return "MenuDishPaneer"
        }
        if name.contains("dal") || name.contains("naan") {
            return "MenuDishDal"
        }
        if name.contains("lemon") || name.contains("nimbu") || name.contains("soda") {
            return "MenuDishLemonade"
        }
        return "MenuDishDessert"
    }
}

struct DualCartView: View {
    let store: SyncTableStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SectionHeader(eyebrow: "Two carts", title: "Ready when you both are", subtitle: "Separate orders, addresses and payments—linked into one shared arrival window.")

                CartCard(participant: store.localParticipant, cart: store.localCart, estimate: store.role == .host ? "42–46 min" : "44–48 min", isReady: store.localReady, editable: true) {
                    store.setLocalReady()
                }
                CartCard(participant: store.remoteParticipant, cart: store.remoteCart, estimate: store.role == .host ? "44–48 min" : "42–46 min", isReady: store.remoteReady, editable: false) {}

                if store.localReady && !store.remoteReady {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("You’re ready. Waiting for \(store.remoteParticipant.name)…")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding()
                }

                Button {
                    store.go(.payment)
                } label: {
                    Label(store.table.hostReady && store.table.partnerReady ? "Choose payment arrangement" : "Waiting for both", systemImage: "creditcard")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!(store.table.hostReady && store.table.partnerReady))
                .opacity(store.table.hostReady && store.table.partnerReady ? 1 : 0.45)
            }
            .padding(20)
        }
        .sensoryFeedback(.success, trigger: store.localReady)
    }
}

struct CartCard: View {
    let participant: Participant
    let cart: Cart
    let estimate: String
    let isReady: Bool
    let editable: Bool
    let readyAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                AvatarView(participant: participant)
                VStack(alignment: .leading) {
                    Text("\(participant.name)’s cart").font(.headline)
                    Text(participant.address.line).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if isReady {
                    Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(Brand.green)
                }
            }
            Divider()
            ForEach(cart.items) { item in
                HStack {
                    Text("\(item.quantity)×").foregroundStyle(.secondary)
                    Text(item.menuItem.name).lineLimit(1)
                    Spacer()
                    Text(item.subtotal.rupees)
                }
                .font(.subheadline)
            }
            HStack {
                Label(estimate, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(cart.total.rupees).font(.title3.bold())
            }
            if editable {
                Button(isReady ? "I’m ready ✓" : "I’m Ready", action: readyAction)
                    .buttonStyle(.borderedProminent)
                    .tint(isReady ? Brand.green : Brand.red)
                    .frame(maxWidth: .infinity)
            } else if !isReady {
                Label("Only \(participant.name) can edit or confirm this cart", systemImage: "lock.fill")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .softCard()
    }
}

struct CheckoutView: View {
    let store: SyncTableStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SectionHeader(eyebrow: "Linked checkout", title: "Two payments. One shared window.", subtitle: "We validate both menus, authorize each payment separately, then submit the linked orders together.")

                VStack(spacing: 14) {
                    paymentRow(store.table.host, total: store.table.hostCart.total, method: "Visa •••• 4821")
                    Divider()
                    paymentRow(store.table.partner, total: store.table.partnerCart.total, method: "UPI • aisha@okhdfc")
                }
                .softCard()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Shared target", systemImage: "clock.badge.checkmark.fill")
                        .font(.headline).foregroundStyle(Brand.red)
                    Text("Expected within \(store.predictedDifference) \(store.predictedDifference == 1 ? "minute" : "minutes") of each other")
                        .font(.title3.bold())
                    Text("We coordinate kitchen start timing and courier assignment. Live estimates remain visible and may differ.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .softCard()

                VStack(alignment: .leading, spacing: 10) {
                    Label("Confirmed payment plan", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(Brand.green)
                    Text(store.paymentSummary).font(.title3.bold())
                    Text("Final total \(store.combinedFinalAmount.rupees)")
                        .foregroundStyle(.secondary)
                    HStack {
                        Label("Aniket confirmed", systemImage: "checkmark.circle.fill")
                        Spacer()
                        Label("\(store.table.partner.name) confirmed", systemImage: "checkmark.circle.fill")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Brand.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .softCard()

                Button {
                    if store.table.orders.isEmpty {
                        Task { await store.authorizeAndSubmit() }
                    } else {
                        store.go(.tracking)
                    }
                } label: {
                    if store.isSubmitting {
                        HStack { ProgressView().tint(.white); Text("Authorizing both payments…") }
                    } else if !store.table.orders.isEmpty {
                        Label("View live linked orders", systemImage: "location.fill")
                    } else {
                        Label("Authorize my payment & link orders", systemImage: "lock.shield.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(store.isSubmitting)

                Label("Mock payments • no charge will be made", systemImage: "checkmark.shield")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }

    private func paymentRow(_ participant: Participant, total: Int, method: String) -> some View {
        HStack {
            AvatarView(participant: participant)
            VStack(alignment: .leading, spacing: 3) {
                Text(participant.name).font(.headline)
                Text(method).font(.caption).foregroundStyle(.secondary)
                Text(participant.address.line).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(total.rupees).font(.headline)
                Label("Ready", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(Brand.green)
            }
        }
    }
}
