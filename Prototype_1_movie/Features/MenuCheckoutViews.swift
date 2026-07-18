import SwiftUI

struct SharedMenuView: View {
    let store: SyncTableStore
    @State private var viewingOther = false

    private var pair: RestaurantPair? { store.table.selectedPair }
    private var menu: [MenuItem] {
        viewingOther ? (store.remoteRestaurant?.menu ?? []) : (store.localRestaurant?.menu ?? [])
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: pair?.theme ?? "Shared menu",
                    title: "Choose dinner together",
                    subtitle: "You can see \(store.remoteParticipant.name)’s cart, but only they can change it."
                )
                Picker("Whose local menu", selection: $viewingOther) {
                    Text("Your menu • \(store.localParticipant.city)").tag(false)
                    Text("\(store.remoteParticipant.name) • \(store.remoteParticipant.city)").tag(true)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 14) {
                    if let event = store.events.first {
                        Label(event.text, systemImage: event.symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Brand.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        Label("Aisha is viewing mains", systemImage: "eye.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                .padding(20)
                .padding(.bottom, 85)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                store.go(.carts)
            } label: {
                HStack {
                    Text("View both carts")
                    Spacer()
                    Text("\(store.localCart.itemCount) items • \(store.localCart.total.rupees)")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
            .background(.ultraThinMaterial)
        }
        .onAppear {
            if store.backendConnected == false && store.table.partnerCart.items.isEmpty {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.2))
                    store.simulatePartnerAction()
                }
            }
        }
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
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Brand.peach.opacity(0.7))
                    .frame(width: 88, height: 88)
                Image(systemName: item.symbol)
                    .font(.system(size: 31))
                    .foregroundStyle(Brand.redDark)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: item.isVegetarian ? "leaf.fill" : "circle.fill")
                        .font(.caption2).foregroundStyle(item.isVegetarian ? Brand.green : Brand.red)
                    Text(item.name).font(.headline)
                }
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let counterpart {
                    Label("Twin: \(counterpart.name)", systemImage: "arrow.left.arrow.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Brand.red)
                        .lineLimit(1)
                }
                HStack {
                    Text(item.price.rupees).font(.subheadline.bold())
                    Spacer()
                    if editable {
                        if quantity > 0 {
                            HStack(spacing: 12) {
                                Button(action: remove) { Image(systemName: "minus") }
                                Text("\(quantity)").font(.headline.monospacedDigit())
                                Button(action: add) { Image(systemName: "plus") }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Brand.red.opacity(0.1), in: Capsule())
                        } else {
                            Button("Add", action: add).buttonStyle(.bordered).tint(Brand.red)
                        }
                    } else {
                        Label("View only", systemImage: "eye").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.price.rupees), \(item.description)")
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
                Label("Only Aisha can edit or confirm this cart", systemImage: "lock.fill")
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
                        Label("Aisha confirmed", systemImage: "checkmark.circle.fill")
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
                Text(participant.address.line).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(total.rupees).font(.headline)
                Label("Ready", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(Brand.green)
            }
        }
    }
}
