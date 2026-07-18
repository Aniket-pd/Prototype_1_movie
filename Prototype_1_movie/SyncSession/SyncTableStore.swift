import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class SyncTableStore {
    var stage: AppStage = .home
    var path: [AppStage] = []
    var table: SyncTable
    var matches: [RestaurantPair] = []
    var isMatching = false
    var events: [PartnerPresenceEvent] = []
    var selectedCategory = "Mains"
    var showDeveloperMenu = false
    var isSubmitting = false
    var errorMessage: String?
    var countdown: Int?
    var hostReadyToEat = false
    var partnerReadyToEat = false
    var reaction: String?
    var liveActivityStarted = false
    var connectionState: BackendConnectionState = .loading
    let role: DemoUserRole

    private let catalogue: RestaurantCatalogueService
    private let matcher: RestaurantMatchingService
    private let orderService: LinkedOrderService
    private let backend: DemoBackendService?
    private var simulationTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var syncTask: Task<Void, Never>?
    private var appliedRevision = -1

    init(
        catalogue: RestaurantCatalogueService? = nil,
        matcher: RestaurantMatchingService? = nil,
        orderService: LinkedOrderService? = nil,
        backend: DemoBackendService? = nil,
        role: DemoUserRole? = nil
    ) {
        self.catalogue = catalogue ?? MockRestaurantCatalogueService()
        self.matcher = matcher ?? DeterministicRestaurantMatchingService()
        self.orderService = orderService ?? MockLinkedOrderService()
        self.role = role ?? DemoRuntimeConfiguration.role
        if let backend {
            self.backend = backend
        } else if let url = DemoRuntimeConfiguration.backendURL {
            self.backend = HTTPDemoBackendService(baseURL: url)
        } else {
            self.backend = nil
        }
        table = Self.emptyTable(id: "")
    }

    var backendConnected: Bool { connectionState == .synced }
    var partnerJoined: Bool { bothConnected }
    var bothConnected: Bool { table.hostConnected && table.partnerConnected }
    var hasActiveTable: Bool { !table.id.isEmpty }
    var inviteCode: String { table.id.replacing("ST-", with: "") }
    var localParticipant: Participant { role == .host ? table.host : table.partner }
    var remoteParticipant: Participant { role == .host ? table.partner : table.host }
    var localConnected: Bool { role == .host ? table.hostConnected : table.partnerConnected }
    var remoteConnected: Bool { role == .host ? table.partnerConnected : table.hostConnected }
    var localCart: Cart { role == .host ? table.hostCart : table.partnerCart }
    var remoteCart: Cart { role == .host ? table.partnerCart : table.hostCart }
    var localReady: Bool { role == .host ? table.hostReady : table.partnerReady }
    var remoteReady: Bool { role == .host ? table.partnerReady : table.hostReady }
    var localRestaurant: Restaurant? {
        role == .host ? table.selectedPair?.hostRestaurant : table.selectedPair?.partnerRestaurant
    }
    var remoteRestaurant: Restaurant? {
        role == .host ? table.selectedPair?.partnerRestaurant : table.selectedPair?.hostRestaurant
    }
    var localReadyToEat: Bool { role == .host ? hostReadyToEat : partnerReadyToEat }
    var hostDeliveryCharge: Int { table.hostCart.items.isEmpty ? 0 : 39 }
    var partnerDeliveryCharge: Int { table.partnerCart.items.isEmpty ? 0 : 35 }
    var hostTax: Int { Int((Double(table.hostCart.total) * 0.05).rounded()) }
    var partnerTax: Int { Int((Double(table.partnerCart.total) * 0.05).rounded()) }
    var hostFinalAmount: Int { table.hostCart.total + hostDeliveryCharge + hostTax }
    var partnerFinalAmount: Int { table.partnerCart.total + partnerDeliveryCharge + partnerTax }
    var combinedFinalAmount: Int { hostFinalAmount + partnerFinalAmount }
    var bothPaymentConfirmed: Bool {
        table.paymentDecision.confirmedBy.contains(table.host.id)
            && table.paymentDecision.confirmedBy.contains(table.partner.id)
            && table.paymentDecision.arrangement != nil
            && (table.paymentDecision.arrangement != .onePays || table.paymentDecision.payerID != nil)
    }
    var paymentSummary: String {
        switch table.paymentDecision.arrangement {
        case .splitEqually: return "Split equally"
        case .ownOrder: return "Each person paid for their own order"
        case .onePays:
            let payer = table.paymentDecision.payerID == table.host.id ? table.host.name : table.partner.name
            return "\(payer) paid for everything"
        case nil: return "Payment not selected"
        }
    }

    func connectToDemoBackend() async {
        guard syncTask == nil else { return }
        guard let backend else {
            connectionState = .disconnected
            return
        }
        connectionState = .loading
        let savedID = UserDefaults.standard.string(forKey: sessionDefaultsKey) ?? ""
        do {
            if !savedID.isEmpty, let remote = try await backend.snapshot(tableID: savedID) {
                table = remote.table
                apply(remote)
                connectionState = .synced
                stage = .invite
            } else {
                _ = try await backend.snapshot(tableID: "__connection_probe__")
                connectionState = .synced
                clearSavedSession()
            }
        } catch {
            connectionState = .error("Demo server unavailable")
        }

        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, let backend = self.backend else { return }
                guard self.hasActiveTable else {
                    try? await Task.sleep(for: .milliseconds(3_750))
                    do {
                        _ = try await backend.snapshot(tableID: "__connection_probe__")
                        self.connectionState = .synced
                    } catch {
                        self.connectionState = .disconnected
                    }
                    continue
                }
                do {
                    if let remote = try await backend.snapshot(tableID: self.table.id) {
                        self.connectionState = .synced
                        self.apply(remote)
                    } else {
                        self.connectionState = .error("Table no longer exists")
                    }
                } catch {
                    self.connectionState = .disconnected
                }
            }
        }
    }

    func createTable() async {
        guard let backend else {
            errorMessage = "The demo backend is unavailable."
            return
        }
        connectionState = .loading
        let code = Self.makeInviteCode()
        table = Self.emptyTable(id: "ST-\(code)")
        if role == .host { table.hostConnected = true } else { table.partnerConnected = true }
        appliedRevision = -1
        do {
            let created = try await backend.perform(.bootstrap(makeSnapshot()), tableID: table.id)
            apply(created)
            let joined = try await backend.perform(.join(role), tableID: table.id)
            apply(joined)
            persistSession()
            connectionState = .synced
            go(.invite)
        } catch {
            connectionState = .error("Could not create table")
            errorMessage = "Could not create a Sync Table. Check the demo server and try again."
        }
    }

    func joinTable(code: String) async {
        guard let backend else {
            errorMessage = "The demo backend is unavailable."
            return
        }
        let codeOrLink = URL(string: code)?.lastPathComponent ?? code
        let normalized = codeOrLink
            .uppercased()
            .replacing("ST-", with: "")
            .filter { $0.isLetter || $0.isNumber }
        guard normalized.count == 4 else {
            errorMessage = "Enter the four-character invite code."
            return
        }
        connectionState = .loading
        let tableID = "ST-\(normalized)"
        do {
            guard let remote = try await backend.snapshot(tableID: tableID) else {
                connectionState = .synced
                errorMessage = "We couldn’t find that Sync Table."
                return
            }
            table = remote.table
            appliedRevision = remote.revision
            applyContents(remote)
            let joined = try await backend.perform(.join(role), tableID: tableID)
            apply(joined)
            persistSession()
            connectionState = .synced
            announce("\(localParticipant.name) joined from \(localParticipant.city)", symbol: "person.2.fill")
            go(.invite)
        } catch {
            connectionState = .error("Could not join table")
            errorMessage = "Could not join this Sync Table. Check the connection and try again."
        }
    }

    func leaveTable() {
        simulationTask?.cancel()
        countdownTask?.cancel()
        clearSavedSession()
        table = Self.emptyTable(id: "")
        appliedRevision = -1
        events = []
        matches = []
        stage = .home
    }

    func go(_ destination: AppStage) {
        withAnimation(.snappy) { stage = destination }
    }

    func joinPartner() {
        let otherRole: DemoUserRole = role == .host ? .partner : .host
        send(.join(otherRole))
        announce("\(remoteParticipant.name) joined from \(remoteParticipant.city)", symbol: "person.2.fill")
    }

    func selectOrderingMode(_ mode: OrderingMode) {
        table.orderingMode = mode
        table.selectedPair = nil
        table.hostCart.items = []
        table.partnerCart.items = []
        table.paymentDecision = .init()
        send(.orderingMode(mode))
    }

    func findMatches() async {
        isMatching = true
        async let hostRestaurants = catalogue.restaurants(in: table.host.city)
        async let partnerRestaurants = catalogue.restaurants(in: table.partner.city)
        let result = await matcher.matches(host: hostRestaurants, partner: partnerRestaurants)
        try? await Task.sleep(for: .milliseconds(700))
        switch table.orderingMode {
        case .sameChain:
            matches = result.filter { $0.hostRestaurant.name == $0.partnerRestaurant.name }
        case .differentRestaurants:
            matches = result.filter { $0.hostRestaurant.name != $0.partnerRestaurant.name }
        case .blend, nil:
            matches = Array(result.prefix(3))
        }
        if matches.isEmpty { matches = Array(result.prefix(3)) }
        isMatching = false
    }

    func select(_ pair: RestaurantPair) {
        table.selectedPair = pair
        table.hostCart.items = []
        table.partnerCart.items = []
        send(.selectPair(pair))
    }

    func addHostItem(_ item: MenuItem) { addLocalItem(item) }

    func addLocalItem(_ item: MenuItem) {
        if role == .host { add(item, to: &table.hostCart) }
        else { add(item, to: &table.partnerCart) }
        send(.cart(role: role, item: item, delta: 1))
        announce("\(localParticipant.name) added \(item.name)", symbol: "plus.circle.fill")
    }

    private func add(_ item: MenuItem, to cart: inout Cart) {
        if let index = cart.items.firstIndex(where: { $0.menuItem.id == item.id }) {
            cart.items[index].quantity += 1
        } else {
            cart.items.append(.init(menuItem: item, quantity: 1))
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func removeHostItem(_ item: MenuItem) { removeLocalItem(item) }

    func removeLocalItem(_ item: MenuItem) {
        if role == .host { remove(item, from: &table.hostCart) }
        else { remove(item, from: &table.partnerCart) }
        send(.cart(role: role, item: item, delta: -1))
    }

    private func remove(_ item: MenuItem, from cart: inout Cart) {
        guard let index = cart.items.firstIndex(where: { $0.menuItem.id == item.id }) else { return }
        if cart.items[index].quantity > 1 { cart.items[index].quantity -= 1 }
        else { cart.items.remove(at: index) }
    }

    func simulatePartnerAction() {
        guard let menu = table.selectedPair?.partnerRestaurant.menu, !menu.isEmpty else { return }
        let next = menu[table.partnerCart.items.count % menu.count]
        add(next, to: &table.partnerCart)
        send(.cart(role: .partner, item: next, delta: 1))
        announce("Aisha added \(next.name)", symbol: "plus.circle.fill")
    }

    func seedCarts() {
        guard let pair = table.selectedPair else { return }
        if table.hostCart.items.isEmpty {
            add(pair.hostRestaurant.menu[0], to: &table.hostCart)
            send(.cart(role: .host, item: pair.hostRestaurant.menu[0], delta: 1))
        }
        if table.partnerCart.items.isEmpty { simulatePartnerAction() }
    }

    func setHostReady() { setLocalReady() }

    func setLocalReady() {
        let value = !localReady
        if role == .host { table.hostReady = value } else { table.partnerReady = value }
        send(.ready(role: role, value: value))
        announce("\(localParticipant.name) is \(value ? "ready" : "still choosing")", symbol: value ? "checkmark.circle.fill" : "clock")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func setBothReady() {
        seedCarts()
        table.hostReady = true
        table.partnerReady = true
        send(.ready(role: .host, value: true))
        send(.ready(role: .partner, value: true))
    }

    func selectPayment(_ arrangement: PaymentArrangement, payerID: UUID? = nil) {
        table.paymentDecision = .init(
            arrangement: arrangement,
            payerID: arrangement == .onePays ? payerID : nil,
            confirmedBy: []
        )
        send(.payment(table.paymentDecision))
    }

    func confirmPaymentDecision() {
        table.paymentDecision.confirmedBy.insert(localParticipant.id)
        send(.confirmPayment(localParticipant.id))
        announce("\(localParticipant.name) confirmed \(paymentSummary.lowercased())", symbol: "checkmark.shield.fill")
    }

    func authorizeAndSubmit() async {
        guard bothPaymentConfirmed else {
            errorMessage = "Both people must confirm the payment arrangement."
            return
        }
        isSubmitting = true
        do {
            try? await Task.sleep(for: .milliseconds(700))
            table.orders = try await orderService.submit(table: table)
            send(.setOrders(table.orders))
            isSubmitting = false
            go(.tracking)
            if role == .host { startAutomaticDeliverySimulation() }
            await startLiveActivityIfPossible()
        } catch {
            errorMessage = "Both carts need an item and both people must be ready."
            isSubmitting = false
        }
    }

    var sharedMilestone: SharedMilestone {
        guard table.orders.count == 2 else { return .linked }
        let minimum = table.orders.map(\.status).min() ?? .authorized
        switch minimum {
        case .awaitingAuthorization, .authorized: return .linked
        case .confirmed: return .confirmed
        case .preparing, .readyForCourier: return .preparing
        case .outForDelivery: return .onTheWay
        case .delivered: return .arrived
        }
    }

    var predictedDifference: Int {
        guard table.orders.count == 2 else { return table.selectedPair?.score.predictedDifference ?? 3 }
        return abs(table.orders[0].estimate.minutes - table.orders[1].estimate.minutes)
    }

    func advanceSimulation() {
        guard table.orders.count == 2 else { return }
        if table.orders[0].status < .delivered {
            table.orders[0].status = IndividualOrderStatus(rawValue: table.orders[0].status.rawValue + 1) ?? .delivered
        } else if table.orders[1].status < .delivered {
            table.orders[1].status = IndividualOrderStatus(rawValue: table.orders[1].status.rawValue + 1) ?? .delivered
        }
        if table.orders[0].status.rawValue > table.orders[1].status.rawValue + 1 {
            table.orders[1].status = IndividualOrderStatus(rawValue: table.orders[1].status.rawValue + 1) ?? .delivered
        }
        updateActivity()
        send(.setOrders(table.orders))
    }

    func injectDelay() {
        guard table.orders.count == 2 else { return }
        table.orders[1].estimate.minutes += 4
        table.orders[1].estimate.window = "8:10–8:14 PM"
        announce("Aisha’s estimate updated honestly", symbol: "clock.badge.exclamationmark")
        updateActivity()
        send(.setOrders(table.orders))
    }

    func completeDeliveries() {
        guard table.orders.count == 2 else { return }
        simulationTask?.cancel()
        table.orders[0].status = .delivered
        table.orders[1].status = .delivered
        updateActivity()
        send(.setOrders(table.orders))
    }

    func startAutomaticDeliverySimulation() {
        simulationTask?.cancel()
        simulationTask = Task { [weak self] in
            for _ in 0..<7 {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                self?.advanceSimulation()
            }
            self?.completeDeliveries()
        }
    }

    func beginFirstBite() {
        if role == .host { hostReadyToEat = true } else { partnerReadyToEat = true }
        send(.readyToEat(role: role, value: true))
        maybeStartCountdown()
    }

    func enterDining() { go(.dining) }

    func sendReaction(_ emoji: String) {
        reaction = emoji
        announce("\(localParticipant.name) reacted \(emoji)", symbol: "heart.fill")
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func finishMeal() {
        let hostDish = table.hostCart.items.first?.menuItem.name ?? "Dinner"
        let partnerDish = table.partnerCart.items.first?.menuItem.name ?? "Dinner"
        let restaurants = [table.selectedPair?.hostRestaurant.name, table.selectedPair?.partnerRestaurant.name]
            .compactMap { $0 }
            .joined(separator: " • ")
        let memory = SyncMemory(
            title: table.selectedPair?.theme ?? "Dinner Together",
            date: .now,
            cities: "\(table.host.city) • \(table.partner.city)",
            dishes: "\(hostDish) + \(partnerDish)",
            theme: table.orderingMode?.title ?? "Sync Table",
            restaurantInformation: restaurants,
            paymentSummary: paymentSummary
        )
        table.memory = memory
        send(.memory(memory))
        go(.memory)
    }

    func openMemory() {
        if table.memory == nil {
            errorMessage = "The shared memory is still syncing."
        } else {
            go(.memory)
        }
    }

    func recreateTable() {
        let tableID = table.id
        let hostConnected = table.hostConnected
        let partnerConnected = table.partnerConnected
        table = Self.emptyTable(id: tableID)
        table.hostConnected = hostConnected
        table.partnerConnected = partnerConnected
        events = []
        matches = []
        countdown = nil
        hostReadyToEat = false
        partnerReadyToEat = false
        appliedRevision = -1
        send(.reset(makeSnapshot()))
        go(.modeSelection)
    }

    func reset() { leaveTable() }

    private func maybeStartCountdown() {
        guard role == .host, hostReadyToEat, partnerReadyToEat, countdown == nil, countdownTask == nil else { return }
        countdownTask = Task { [weak self] in
            guard let self else { return }
            for value in stride(from: 3, through: 1, by: -1) {
                self.countdown = value
                self.send(.countdown(value))
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                try? await Task.sleep(for: .seconds(1))
            }
            self.countdown = 0
            self.send(.countdown(0))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.countdownTask = nil
        }
    }

    private func announce(_ text: String, symbol: String) {
        let event = PartnerPresenceEvent(text: text, symbol: symbol, date: .now)
        events.insert(event, at: 0)
        send(.event(event))
    }

    private func send(_ action: DemoBackendAction) {
        guard let backend, hasActiveTable else { return }
        let tableID = table.id
        Task { [weak self] in
            do {
                let remote = try await backend.perform(action, tableID: tableID)
                self?.connectionState = .synced
                self?.apply(remote)
            } catch {
                self?.connectionState = .disconnected
            }
        }
    }

    private func makeSnapshot() -> DemoBackendSnapshot {
        .init(
            revision: max(0, appliedRevision),
            stage: .home,
            partnerJoined: table.partnerConnected,
            table: table,
            events: events,
            hostReadyToEat: hostReadyToEat,
            partnerReadyToEat: partnerReadyToEat,
            countdown: countdown
        )
    }

    private func apply(_ snapshot: DemoBackendSnapshot) {
        guard snapshot.revision > appliedRevision else { return }
        appliedRevision = snapshot.revision
        applyContents(snapshot)
    }

    private func applyContents(_ snapshot: DemoBackendSnapshot) {
        withAnimation(.snappy) {
            table = snapshot.table
            events = snapshot.events
            hostReadyToEat = snapshot.hostReadyToEat
            partnerReadyToEat = snapshot.partnerReadyToEat
            countdown = snapshot.countdown
        }
        maybeStartCountdown()
    }

    private var sessionDefaultsKey: String { "sync-table-session-\(role.rawValue)" }

    private func persistSession() {
        UserDefaults.standard.set(table.id, forKey: sessionDefaultsKey)
    }

    private func clearSavedSession() {
        UserDefaults.standard.removeObject(forKey: sessionDefaultsKey)
    }

    private static func makeInviteCode() -> String {
        String(UUID().uuidString.replacing("-", with: "").prefix(4)).uppercased()
    }

    private static func emptyTable(id: String) -> SyncTable {
        SyncTable(
            id: id,
            createdAt: .now,
            host: DemoData.aniket,
            partner: DemoData.aisha,
            selectedPair: nil,
            hostCart: .init(id: UUID(), ownerID: DemoData.aniket.id, items: []),
            partnerCart: .init(id: UUID(), ownerID: DemoData.aisha.id, items: []),
            hostReady: false,
            partnerReady: false,
            orders: [],
            hostConnected: false,
            partnerConnected: false,
            orderingMode: nil,
            paymentDecision: .init(),
            memory: nil
        )
    }
}
