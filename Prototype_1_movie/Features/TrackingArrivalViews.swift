import SwiftUI
import MapKit

struct TrackingView: View {
    let store: SyncTableStore
    @State private var mapPosition: MapCameraPosition = .region(.init(
        center: .init(latitude: 15.9, longitude: 75.2),
        span: .init(latitudeDelta: 8.5, longitudeDelta: 8.5)
    ))

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SectionHeader(eyebrow: "Live Sync • \(store.table.id)", title: store.sharedMilestone.title, subtitle: honestStatus)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SHARED ARRIVAL WINDOW").font(.caption.bold()).tracking(1)
                            Text("8:06–8:12 PM").font(.title.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Δ \(store.predictedDifference) min").font(.title3.bold())
                            Text("current prediction").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Expected within \(store.predictedDifference) minutes of each other")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.green)
                }
                .softCard()

                if store.table.orders.count == 2 {
                    orderCard(order: store.table.orders[0], participant: store.table.host)
                    orderCard(order: store.table.orders[1], participant: store.table.partner)
                }

                courierMap
                    .frame(height: 250)
                    .clipShape(.rect(cornerRadius: 22))
                    .overlay(alignment: .topLeading) {
                        Text("Two local courier journeys")
                            .font(.caption.bold())
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(10)
                    }

                SharedTimeline(current: store.sharedMilestone)

                VStack(spacing: 8) {
                    Text("In-app Live Activity preview")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                    LiveActivityPreview(store: store)
                }

                #if DEBUG
                Button("Demo: Advance delivery") { store.advanceSimulation() }
                    .buttonStyle(.bordered)
                #endif

                if store.table.orders.count == 2,
                   store.table.orders.allSatisfy({ $0.status == .delivered }) {
                    Button("Continue to first bite", systemImage: "fork.knife") {
                        store.go(.firstBite)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(20)
        }
    }

    private var honestStatus: String {
        guard store.table.orders.count == 2 else { return "The orders are being linked." }
        let local = store.table.orders.first(where: { $0.ownerID == store.localParticipant.id })?.status ?? .authorized
        let remote = store.table.orders.first(where: { $0.ownerID == store.remoteParticipant.id })?.status ?? .authorized
        if local > remote {
            return "Your order is \(local.title.lowercased()). Waiting for \(store.remoteParticipant.name)’s restaurant."
        }
        if remote > local {
            return "\(store.remoteParticipant.name)’s order is \(remote.title.lowercased()). Your restaurant is catching up."
        }
        return "Both individual orders have reached this shared milestone."
    }

    private func orderCard(order: LinkedOrder, participant: Participant) -> some View {
        HStack(spacing: 14) {
            AvatarView(participant: participant)
            VStack(alignment: .leading, spacing: 5) {
                Text(order.restaurantName).font(.headline)
                Text(order.id).font(.caption.monospaced()).foregroundStyle(.secondary)
                Label(order.status.title, systemImage: order.status.symbol)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.red)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(order.estimate.window).font(.caption.bold())
                ProgressView(value: Double(order.status.rawValue), total: 6).frame(width: 72).tint(Brand.red)
                Text(order.total.rupees).font(.caption).foregroundStyle(.secondary)
            }
        }
        .softCard()
    }

    private var courierMap: some View {
        Map(position: $mapPosition, interactionModes: [.pan, .zoom]) {
            Marker("Mumbai order", systemImage: "takeoutbag.and.cup.and.straw.fill", coordinate: store.table.host.address.latitudeLongitude)
                .tint(Brand.red)
            Marker("Bengaluru order", systemImage: "takeoutbag.and.cup.and.straw.fill", coordinate: store.table.partner.address.latitudeLongitude)
                .tint(.orange)
            if let pair = store.table.selectedPair {
                Marker(pair.hostRestaurant.name, coordinate: pair.hostRestaurant.coordinate.clLocation).tint(.brown)
                Marker(pair.partnerRestaurant.name, coordinate: pair.partnerRestaurant.coordinate.clLocation).tint(.brown)
                MapPolyline(coordinates: [pair.hostRestaurant.coordinate.clLocation, store.table.host.address.latitudeLongitude])
                    .stroke(Brand.red, lineWidth: 4)
                MapPolyline(coordinates: [pair.partnerRestaurant.coordinate.clLocation, store.table.partner.address.latitudeLongitude])
                    .stroke(.orange, lineWidth: 4)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .accessibilityLabel("Map showing separate courier routes in Mumbai and Bengaluru")
    }
}

private extension DeliveryAddress {
    var latitudeLongitude: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

struct SharedTimeline: View {
    let current: SharedMilestone

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shared milestones").font(.headline)
            ForEach(SharedMilestone.allCases, id: \.self) { milestone in
                HStack(spacing: 12) {
                    Image(systemName: milestone.rawValue <= current.rawValue ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(milestone.rawValue <= current.rawValue ? Brand.green : .secondary)
                    Text(milestone.title)
                        .font(.subheadline)
                        .foregroundStyle(milestone.rawValue <= current.rawValue ? .primary : .secondary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}

struct LiveActivityPreview: View {
    let store: SyncTableStore

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "fork.knife.circle.fill").foregroundStyle(Brand.red)
                Text("Sync Table").font(.headline)
                Spacer()
                Text(store.table.id).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                activityPerson(store.table.host, order: store.table.orders.first)
                Image(systemName: "link").foregroundStyle(Brand.red)
                activityPerson(store.table.partner, order: store.table.orders.dropFirst().first)
            }
            Text("Expected within \(store.predictedDifference) min of each other")
                .font(.caption.bold()).foregroundStyle(Brand.green)
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 20))
    }

    private func activityPerson(_ person: Participant, order: LinkedOrder?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.name).font(.caption.bold())
            Text(order?.status.title ?? "Linked").font(.caption).foregroundStyle(.white.opacity(0.7))
            ProgressView(value: Double(order?.status.rawValue ?? 0), total: 6).tint(person.isHost ? Brand.red : .orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FirstBiteView: View {
    let store: SyncTableStore

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(Brand.peach.opacity(0.5)).frame(width: 190, height: 190)
                if let count = store.countdown {
                    Text(count == 0 ? "🍽️" : "\(count)")
                        .font(.system(size: 78, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                } else {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 92)).foregroundStyle(Brand.red)
                }
            }
            SectionHeader(eyebrow: "Both orders arrived", title: store.countdown == 0 ? "Your table is ready" : "One last little sync", subtitle: "When you’re both settled, begin the first bite together.")
                .multilineTextAlignment(.center)
            HStack(spacing: 28) {
                readyPerson(store.table.host, ready: store.hostReadyToEat)
                readyPerson(store.table.partner, ready: store.partnerReadyToEat)
            }
            Spacer()
            Button {
                if store.countdown == 0 {
                    store.enterDining()
                } else {
                    store.beginFirstBite()
                }
            } label: {
                Label(firstBiteButtonTitle, systemImage: "fork.knife")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(store.localReadyToEat && store.countdown != 0)
        }
        .padding(24)
        .sensoryFeedback(.impact(weight: .heavy), trigger: store.countdown)
    }

    private var firstBiteButtonTitle: String {
        if store.countdown == 0 { return "Join the table" }
        if store.localReadyToEat { return "Waiting for your tablemate…" }
        return "I’m Ready to Eat"
    }

    private func readyPerson(_ participant: Participant, ready: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(participant: participant, size: 66)
                Image(systemName: ready ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(ready ? Brand.green : .secondary)
                    .background(.background, in: Circle())
            }
            Text(participant.name).font(.headline)
            Text(ready ? "Ready" : "Getting settled").font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct DiningView: View {
    let store: SyncTableStore
    @State private var selectedReaction = ""

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            HStack {
                AvatarView(participant: store.table.host, size: 74)
                Image(systemName: "heart.fill").font(.title).foregroundStyle(Brand.red)
                AvatarView(participant: store.table.partner, size: 74)
            }
            Text("Dinner, together.")
                .font(.largeTitle.bold())
            Text(store.table.selectedPair?.theme ?? "Your Sync Table")
                .font(.headline).foregroundStyle(Brand.red)
            Text("Mumbai ↔ Bengaluru")
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                ForEach(["😍", "🤌", "🌶️", "😂"], id: \.self) { emoji in
                    Button(emoji) {
                        selectedReaction = emoji
                        store.sendReaction(emoji)
                    }
                    .font(.title)
                    .padding(10)
                    .background(selectedReaction == emoji ? Brand.peach : Color(.secondarySystemBackground), in: Circle())
                    .accessibilityLabel("Send \(emoji) reaction")
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("A tiny conversation card").font(.caption.bold()).foregroundStyle(.secondary)
                Text("What’s the best bite on your plate?")
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard()
            Spacer()
            Button(store.table.memory == nil ? "Save this table as a memory" : "View table memory") {
                if store.table.memory == nil { store.finishMeal() }
                else { store.openMemory() }
            }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .sensoryFeedback(.selection, trigger: selectedReaction)
    }
}

struct MemoryView: View {
    let store: SyncTableStore

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                SectionHeader(eyebrow: "Sync Table memory", title: "A table worth keeping", subtitle: "Your linked orders become a small shared memory—not another receipt.")
                if let memory = store.table.memory {
                    VStack(alignment: .leading, spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Brand.peach.opacity(0.7))
                                .frame(height: 200)
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife.circle.fill").font(.system(size: 66)).foregroundStyle(Brand.red)
                                HStack {
                                    AvatarView(participant: store.table.host)
                                    Image(systemName: "heart.fill").foregroundStyle(Brand.red)
                                    AvatarView(participant: store.table.partner)
                                }
                            }
                        }
                        Text(memory.title).font(.title.bold())
                        Label(memory.date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                        Label("\(store.table.host.name) + \(store.table.partner.name)", systemImage: "person.2.fill")
                        Label(memory.cities, systemImage: "location.fill")
                        Label(memory.dishes, systemImage: "fork.knife")
                            .fixedSize(horizontal: false, vertical: true)
                        Label(memory.restaurantInformation, systemImage: "building.2.fill")
                            .fixedSize(horizontal: false, vertical: true)
                        Label(memory.paymentSummary, systemImage: "creditcard.fill")
                            .fixedSize(horizontal: false, vertical: true)
                        Label(memory.theme, systemImage: "square.grid.2x2.fill")
                        Text("Two locations. Two carts. One shared meal.")
                            .font(.footnote.bold()).foregroundStyle(Brand.red)
                    }
                    .softCard()
                } else {
                    MemoryUnavailableState(connectionState: store.connectionState)
                }
                Button {
                    store.recreateTable()
                } label: {
                    Label("Recreate this table", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Back to Zomato home") { store.leaveTable() }
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

private struct MemoryUnavailableState: View {
    let connectionState: BackendConnectionState

    var body: some View {
        switch connectionState {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading your shared memory…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .softCard()
        case .disconnected, .error:
            ContentUnavailableView(
                "Memory unavailable offline",
                systemImage: "wifi.slash",
                description: Text("Reconnect to restore the latest shared table memory.")
            )
            .softCard()
        case .local, .synced:
            ContentUnavailableView(
                "Memory not saved yet",
                systemImage: "fork.knife.circle",
                description: Text("Finish the shared meal to create this memory.")
            )
            .softCard()
        }
    }
}
