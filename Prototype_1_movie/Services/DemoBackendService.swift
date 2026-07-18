import Foundation

enum DemoUserRole: String, Codable {
    case host
    case partner
}

enum BackendConnectionState: Equatable {
    case loading
    case local
    case disconnected
    case error(String)
    case synced

    var title: String {
        switch self {
        case .loading: "Connecting"
        case .local: "On-device demo"
        case .disconnected: "Disconnected"
        case .error: "Sync error"
        case .synced: "Synced"
        }
    }

    var isHealthy: Bool {
        switch self {
        case .local, .synced:
            true
        case .loading, .disconnected, .error:
            false
        }
    }
}

struct DemoBackendSnapshot: Codable {
    var revision: Int
    var stage: AppStage
    var partnerJoined: Bool
    var table: SyncTable
    var events: [PartnerPresenceEvent]
    var hostReadyToEat: Bool
    var partnerReadyToEat: Bool
    var countdown: Int?
}

enum DemoBackendAction: Encodable {
    case bootstrap(DemoBackendSnapshot)
    case setStage(AppStage)
    case join(DemoUserRole)
    case selectPair(RestaurantPair)
    case cart(role: DemoUserRole, item: MenuItem, delta: Int)
    case ready(role: DemoUserRole, value: Bool)
    case payment(SharedPaymentDecision)
    case confirmPayment(UUID)
    case setOrders([LinkedOrder])
    case event(PartnerPresenceEvent)
    case memory(SyncMemory)
    case readyToEat(role: DemoUserRole, value: Bool)
    case countdown(Int?)
    case reset(DemoBackendSnapshot)

    private enum CodingKeys: String, CodingKey {
        case type, snapshot, stage, pair, role, mode, item, delta, value, payment, participantID, orders, event, memory, countdown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bootstrap(let snapshot):
            try container.encode("bootstrap", forKey: .type)
            try container.encode(snapshot, forKey: .snapshot)
        case .setStage(let stage):
            try container.encode("stage", forKey: .type)
            try container.encode(stage, forKey: .stage)
        case .join(let role):
            try container.encode("join", forKey: .type)
            try container.encode(role, forKey: .role)
        case .selectPair(let pair):
            try container.encode("selectPair", forKey: .type)
            try container.encode(pair, forKey: .pair)
        case .cart(let role, let item, let delta):
            try container.encode("cart", forKey: .type)
            try container.encode(role, forKey: .role)
            try container.encode(item, forKey: .item)
            try container.encode(delta, forKey: .delta)
        case .ready(let role, let value):
            try container.encode("ready", forKey: .type)
            try container.encode(role, forKey: .role)
            try container.encode(value, forKey: .value)
        case .payment(let payment):
            try container.encode("payment", forKey: .type)
            try container.encode(payment, forKey: .payment)
        case .confirmPayment(let participantID):
            try container.encode("confirmPayment", forKey: .type)
            try container.encode(participantID, forKey: .participantID)
        case .setOrders(let orders):
            try container.encode("orders", forKey: .type)
            try container.encode(orders, forKey: .orders)
        case .event(let event):
            try container.encode("event", forKey: .type)
            try container.encode(event, forKey: .event)
        case .memory(let memory):
            try container.encode("memory", forKey: .type)
            try container.encode(memory, forKey: .memory)
        case .readyToEat(let role, let value):
            try container.encode("readyToEat", forKey: .type)
            try container.encode(role, forKey: .role)
            try container.encode(value, forKey: .value)
        case .countdown(let value):
            try container.encode("countdown", forKey: .type)
            try container.encodeIfPresent(value, forKey: .countdown)
        case .reset(let snapshot):
            try container.encode("reset", forKey: .type)
            try container.encode(snapshot, forKey: .snapshot)
        }
    }
}

protocol DemoBackendService: Sendable {
    func snapshot(tableID: String) async throws -> DemoBackendSnapshot?
    func perform(_ action: DemoBackendAction, tableID: String) async throws -> DemoBackendSnapshot
}

struct HTTPDemoBackendService: DemoBackendService {
    let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func snapshot(tableID: String) async throws -> DemoBackendSnapshot? {
        var request = URLRequest(url: tableURL(tableID))
        request.timeoutInterval = 1
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 404 { return nil }
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try decoder.decode(DemoBackendSnapshot.self, from: data)
    }

    func perform(_ action: DemoBackendAction, tableID: String) async throws -> DemoBackendSnapshot {
        var request = URLRequest(url: tableURL(tableID).appending(path: "actions"))
        request.httpMethod = "POST"
        request.timeoutInterval = 2
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(action)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(DemoBackendSnapshot.self, from: data)
    }

    private func tableURL(_ tableID: String) -> URL {
        baseURL.appending(path: "tables").appending(path: tableID)
    }
}

enum DemoRuntimeConfiguration {
    static var role: DemoUserRole {
        guard let value = argumentValue(after: "--sync-role") else { return .host }
        return DemoUserRole(rawValue: value) ?? .host
    }

    static var backendURL: URL? {
        if ProcessInfo.processInfo.arguments.contains("--offline-demo") { return nil }
        let value = argumentValue(after: "--backend-url") ?? "http://localhost:8787"
        return URL(string: value)
    }

    private static func argumentValue(after key: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: key), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
