import Testing
import Foundation
@testable import Prototype_1_movie

@Suite("Sync Table core logic")
struct SyncTableTests {
    @Test("Menu Twin matching is deterministic")
    func matching() async {
        let service = DeterministicRestaurantMatchingService()
        let host = DemoData.catalogue.filter { $0.city == "Mumbai" }
        let partner = DemoData.catalogue.filter { $0.city == "Bengaluru" }
        let first = await service.matches(host: host, partner: partner)
        let second = await service.matches(host: host, partner: partner)
        #expect(first.map(\.score.total) == second.map(\.score.total))
        #expect(first.contains { $0.hostRestaurant.name == "Zomato Kitchen" && $0.partnerRestaurant.name == "Zomato Kitchen" })
        #expect(first.contains { $0.theme == "North Indian Grill Night" })
    }

    @Test("Cart ownership remains separate")
    @MainActor
    func cartOwnership() {
        let store = SyncTableStore()
        store.table.selectedPair = RestaurantPair(
            hostRestaurant: DemoData.catalogue[0],
            partnerRestaurant: DemoData.catalogue[1],
            score: .init(total: 91, menuSimilarity: 89, predictedDifference: 3, priceCompatible: true, prepCompatible: true),
            theme: "North Indian Grill Night"
        )
        store.addHostItem(DemoData.catalogue[0].menu[0])
        #expect(store.table.hostCart.itemCount == 1)
        #expect(store.table.partnerCart.itemCount == 0)
        store.simulatePartnerAction()
        #expect(store.table.hostCart.itemCount == 1)
        #expect(store.table.partnerCart.itemCount == 1)
    }

    @Test("Checkout is gated by both readiness states")
    func readinessGate() async throws {
        let service = MockLinkedOrderService()
        var table = sampleTable()
        await #expect(throws: OrderError.self) { try await service.submit(table: table) }
        table.hostReady = true
        table.partnerReady = true
        let orders = try await service.submit(table: table)
        #expect(orders.count == 2)
        #expect(orders[0].ownerID != orders[1].ownerID)
    }

    @Test("Shared milestone uses the slower individual order")
    @MainActor
    func divergentMilestone() {
        let store = SyncTableStore()
        store.table = sampleTable()
        store.table.orders = sampleOrders(host: .preparing, partner: .confirmed)
        #expect(store.sharedMilestone == .confirmed)
        store.table.orders[1].status = .preparing
        #expect(store.sharedMilestone == .preparing)
    }

    @Test("Fallback profile never invents logistics")
    func foundationFallback() async {
        let first = DemoData.mumbaiMenu[0]
        let second = DemoData.bengaluruMenu[0]
        let profile = await DeterministicMenuTwinService().profile(for: first, counterpart: second)
        #expect(profile.canonicalDishType == "Grilled paneer meal")
        #expect(profile.suitableCounterpart == second.name)
        #expect(profile.isVegetarian)
    }

    @Test("Payment arrangement requires both confirmations")
    @MainActor
    func sharedPaymentConfirmation() {
        let store = SyncTableStore(backend: nil, role: .host)
        store.table = sampleTable()
        store.selectPayment(.onePays, payerID: store.table.host.id)
        store.confirmPaymentDecision()
        #expect(!store.bothPaymentConfirmed)
        store.table.paymentDecision.confirmedBy.insert(store.table.partner.id)
        #expect(store.bothPaymentConfirmed)
        #expect(store.paymentSummary == "Aniket paid for everything")
    }

    @Test("Shared memory survives encoding and decoding")
    func memoryRoundTrip() throws {
        var table = sampleTable()
        table.memory = .init(
            title: "Cosy Noodle Night",
            date: .now,
            cities: "Mumbai • Bengaluru",
            dishes: "Ramen + Noodles",
            theme: "Blend",
            restaurantInformation: "Noodle Theory • Miso Social",
            paymentSummary: "Split equally"
        )
        let data = try JSONEncoder().encode(table)
        let restored = try JSONDecoder().decode(SyncTable.self, from: data)
        #expect(restored.memory == table.memory)
    }

    @Test("Shared data sync does not move the other user")
    @MainActor
    func independentNavigation() async {
        let backend = InMemoryDemoBackend()
        let host = SyncTableStore(backend: backend, role: .host)
        let partner = SyncTableStore(backend: backend, role: .partner)

        await host.connectToDemoBackend()
        await partner.connectToDemoBackend()
        await host.createTable()
        await partner.joinTable(code: host.inviteCode)

        host.go(.modeSelection)
        partner.go(.invite)
        host.selectOrderingMode(.blend)
        try? await Task.sleep(for: .milliseconds(600))

        #expect(host.stage == .modeSelection)
        #expect(partner.stage == .invite)
        #expect(partner.table.orderingMode == .blend)
        #expect(host.bothConnected)
        #expect(partner.bothConnected)
    }

    private func sampleTable() -> SyncTable {
        let pair = RestaurantPair(
            hostRestaurant: DemoData.catalogue[0],
            partnerRestaurant: DemoData.catalogue[1],
            score: .init(total: 91, menuSimilarity: 89, predictedDifference: 3, priceCompatible: true, prepCompatible: true),
            theme: "North Indian Grill Night"
        )
        return .init(
            id: "ST-TEST", createdAt: .now, host: DemoData.aniket, partner: DemoData.aisha, selectedPair: pair,
            hostCart: .init(id: UUID(), ownerID: DemoData.aniket.id, items: [.init(menuItem: DemoData.mumbaiMenu[0], quantity: 1)]),
            partnerCart: .init(id: UUID(), ownerID: DemoData.aisha.id, items: [.init(menuItem: DemoData.bengaluruMenu[0], quantity: 1)]),
            hostReady: false, partnerReady: false, orders: []
        )
    }

    private func sampleOrders(host: IndividualOrderStatus, partner: IndividualOrderStatus) -> [LinkedOrder] {
        [
            .init(id: "A", ownerID: DemoData.aniket.id, restaurantName: "A", address: DemoData.aniket.address, total: 1, status: host, estimate: .init(minutes: 40, window: "8:00"), paymentAuthorized: true),
            .init(id: "B", ownerID: DemoData.aisha.id, restaurantName: "B", address: DemoData.aisha.address, total: 1, status: partner, estimate: .init(minutes: 43, window: "8:03"), paymentAuthorized: true)
        ]
    }
}

@MainActor
private final class InMemoryDemoBackend: DemoBackendService, @unchecked Sendable {
    private var snapshots: [String: DemoBackendSnapshot] = [:]

    func snapshot(tableID: String) async throws -> DemoBackendSnapshot? {
        snapshots[tableID]
    }

    func perform(_ action: DemoBackendAction, tableID: String) async throws -> DemoBackendSnapshot {
        switch action {
        case .bootstrap(let snapshot), .reset(let snapshot):
            if case .bootstrap = action, let existing = snapshots[tableID] { return existing }
            var updated = snapshot
            updated.revision += 1
            snapshots[tableID] = updated
        case .join(let role):
            update(tableID) { snapshot in
                if role == .host { snapshot.table.hostConnected = true }
                else { snapshot.table.partnerConnected = true }
                snapshot.partnerJoined = snapshot.table.partnerConnected
            }
        case .orderingMode(let mode):
            update(tableID) { $0.table.orderingMode = mode }
        case .payment(let payment):
            update(tableID) { $0.table.paymentDecision = payment }
        case .confirmPayment(let participantID):
            update(tableID) { $0.table.paymentDecision.confirmedBy.insert(participantID) }
        case .memory(let memory):
            update(tableID) { $0.table.memory = memory }
        case .cart(let role, let item, let delta):
            update(tableID) { snapshot in
                var cart = role == .host ? snapshot.table.hostCart : snapshot.table.partnerCart
                if let index = cart.items.firstIndex(where: { $0.menuItem.id == item.id }) {
                    cart.items[index].quantity += delta
                } else if delta > 0 {
                    cart.items.append(.init(menuItem: item, quantity: delta))
                }
                if role == .host { snapshot.table.hostCart = cart }
                else { snapshot.table.partnerCart = cart }
            }
        case .ready(let role, let value):
            update(tableID) {
                if role == .host { $0.table.hostReady = value }
                else { $0.table.partnerReady = value }
            }
        case .selectPair(let pair):
            update(tableID) { $0.table.selectedPair = pair }
        case .setOrders(let orders):
            update(tableID) { $0.table.orders = orders }
        case .event(let event):
            update(tableID) { $0.events.insert(event, at: 0) }
        case .readyToEat(let role, let value):
            update(tableID) {
                if role == .host { $0.hostReadyToEat = value }
                else { $0.partnerReadyToEat = value }
            }
        case .countdown(let value):
            update(tableID) { $0.countdown = value }
        case .setStage:
            break
        }
        guard let snapshot = snapshots[tableID] else { throw URLError(.resourceUnavailable) }
        return snapshot
    }

    private func update(_ tableID: String, mutation: (inout DemoBackendSnapshot) -> Void) {
        guard var snapshot = snapshots[tableID] else { return }
        mutation(&snapshot)
        snapshot.revision += 1
        snapshots[tableID] = snapshot
    }
}
