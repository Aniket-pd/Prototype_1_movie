import Foundation
import CoreLocation

enum AppStage: Int, CaseIterable, Codable, Hashable {
    case home, invite, matching, menu, carts, payment, checkout, tracking, firstBite, dining, memory
}

enum PaymentArrangement: String, CaseIterable, Codable, Identifiable {
    case ownOrder
    case onePays

    var id: Self { self }
    var title: String {
        switch self {
        case .ownOrder: "Pay for your own order"
        case .onePays: "One person pays for everything"
        }
    }
}

struct SharedPaymentDecision: Hashable, Codable {
    var arrangement: PaymentArrangement?
    var payerID: UUID?
    var confirmedBy: Set<UUID> = []

    func isConfirmed(by participant: Participant) -> Bool {
        confirmedBy.contains(participant.id)
    }
}

struct Participant: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let initials: String
    let city: String
    let address: DeliveryAddress
    let isHost: Bool
}

struct DeliveryAddress: Hashable, Codable {
    let label: String
    let line: String
    let city: String
    let latitude: Double
    let longitude: Double
}

struct Restaurant: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let city: String
    let cuisine: String
    let rating: Double
    let priceLevel: Int
    let preparationMinutes: Int
    let deliveryMinutes: Int
    let coordinate: Coordinate
    let menu: [MenuItem]
}

struct Coordinate: Hashable, Codable {
    let latitude: Double
    let longitude: Double
    var clLocation: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

struct MenuItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let price: Int
    let category: String
    let isVegetarian: Bool
    let spice: Int
    let symbol: String
    let tags: Set<String>
}

struct MenuTwinProfile: Hashable, Codable {
    let canonicalDishType: String
    let cuisine: String
    let mealCategory: String
    let isVegetarian: Bool
    let flavorProfile: [String]
    let spiceCategory: String
    let cookingStyle: String
    let suitableCounterpart: String
}

struct RestaurantPair: Identifiable, Hashable, Codable {
    let id: UUID
    let hostRestaurant: Restaurant
    let partnerRestaurant: Restaurant
    let score: SyncScore
    let theme: String
    var isSameRestaurant: Bool { hostRestaurant.name == partnerRestaurant.name }

    init(id: UUID = UUID(), hostRestaurant: Restaurant, partnerRestaurant: Restaurant, score: SyncScore, theme: String) {
        self.id = id
        self.hostRestaurant = hostRestaurant
        self.partnerRestaurant = partnerRestaurant
        self.score = score
        self.theme = theme
    }
}

struct SyncScore: Hashable, Codable {
    let total: Int
    let menuSimilarity: Int
    let predictedDifference: Int
    let priceCompatible: Bool
    let prepCompatible: Bool
}

struct CartItem: Identifiable, Hashable, Codable {
    var id: UUID { menuItem.id }
    let menuItem: MenuItem
    var quantity: Int
    var subtotal: Int { menuItem.price * quantity }
}

struct Cart: Identifiable, Hashable, Codable {
    let id: UUID
    let ownerID: UUID
    var items: [CartItem]
    var total: Int { items.reduce(0) { $0 + $1.subtotal } }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
}

enum IndividualOrderStatus: Int, CaseIterable, Codable, Comparable {
    case awaitingAuthorization, authorized, confirmed, preparing, readyForCourier, outForDelivery, delivered

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    var title: String {
        switch self {
        case .awaitingAuthorization: "Awaiting payment"
        case .authorized: "Payment authorized"
        case .confirmed: "Confirmed"
        case .preparing: "Preparing"
        case .readyForCourier: "Courier assigned"
        case .outForDelivery: "Out for delivery"
        case .delivered: "Delivered"
        }
    }
    var symbol: String {
        switch self {
        case .awaitingAuthorization: "creditcard"
        case .authorized: "checkmark.shield"
        case .confirmed: "checkmark.seal"
        case .preparing: "flame"
        case .readyForCourier: "figure.wave"
        case .outForDelivery: "scooter"
        case .delivered: "house.and.flag"
        }
    }
}

struct DeliveryEstimate: Hashable, Codable {
    var minutes: Int
    var window: String
}

struct LinkedOrder: Identifiable, Hashable, Codable {
    let id: String
    let ownerID: UUID
    let restaurantName: String
    let address: DeliveryAddress
    let total: Int
    var status: IndividualOrderStatus
    var estimate: DeliveryEstimate
    var paymentAuthorized: Bool
}

enum SharedMilestone: Int, CaseIterable, Codable {
    case linked, confirmed, preparing, onTheWay, arrived

    var title: String {
        switch self {
        case .linked: "Orders linked"
        case .confirmed: "Sync Table confirmed"
        case .preparing: "Both kitchens cooking"
        case .onTheWay: "Both couriers on the way"
        case .arrived: "Your table has arrived"
        }
    }
}

struct PartnerPresenceEvent: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let symbol: String
    let date: Date

    init(id: UUID = UUID(), text: String, symbol: String, date: Date) {
        self.id = id
        self.text = text
        self.symbol = symbol
        self.date = date
    }
}

struct SyncTable: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let host: Participant
    let partner: Participant
    var selectedPair: RestaurantPair?
    /// The participant who most recently selected the current restaurant pair.
    /// This lets the other participant distinguish a remote selection visually.
    var selectedBy: DemoUserRole?
    var hostCart: Cart
    var partnerCart: Cart
    var hostReady: Bool
    var partnerReady: Bool
    var orders: [LinkedOrder]
    var hostConnected: Bool = false
    var partnerConnected: Bool = false
    var paymentDecision: SharedPaymentDecision = .init()
    var memory: SyncMemory?

    private enum CodingKeys: String, CodingKey {
        case id, createdAt, host, partner, selectedPair, selectedBy, hostCart, partnerCart
        case hostReady, partnerReady, orders, hostConnected, partnerConnected, paymentDecision, memory
    }

    init(
        id: String,
        createdAt: Date,
        host: Participant,
        partner: Participant,
        selectedPair: RestaurantPair?,
        selectedBy: DemoUserRole? = nil,
        hostCart: Cart,
        partnerCart: Cart,
        hostReady: Bool,
        partnerReady: Bool,
        orders: [LinkedOrder],
        hostConnected: Bool = false,
        partnerConnected: Bool = false,
        paymentDecision: SharedPaymentDecision = .init(),
        memory: SyncMemory? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.host = host
        self.partner = partner
        self.selectedPair = selectedPair
        self.selectedBy = selectedBy
        self.hostCart = hostCart
        self.partnerCart = partnerCart
        self.hostReady = hostReady
        self.partnerReady = partnerReady
        self.orders = orders
        self.hostConnected = hostConnected
        self.partnerConnected = partnerConnected
        self.paymentDecision = paymentDecision
        self.memory = memory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            host: try container.decode(Participant.self, forKey: .host),
            partner: try container.decode(Participant.self, forKey: .partner),
            selectedPair: try container.decodeIfPresent(RestaurantPair.self, forKey: .selectedPair),
            selectedBy: try container.decodeIfPresent(DemoUserRole.self, forKey: .selectedBy),
            hostCart: try container.decode(Cart.self, forKey: .hostCart),
            partnerCart: try container.decode(Cart.self, forKey: .partnerCart),
            hostReady: try container.decode(Bool.self, forKey: .hostReady),
            partnerReady: try container.decode(Bool.self, forKey: .partnerReady),
            orders: try container.decode([LinkedOrder].self, forKey: .orders),
            hostConnected: try container.decodeIfPresent(Bool.self, forKey: .hostConnected) ?? false,
            partnerConnected: try container.decodeIfPresent(Bool.self, forKey: .partnerConnected) ?? false,
            paymentDecision: try container.decodeIfPresent(SharedPaymentDecision.self, forKey: .paymentDecision) ?? .init(),
            memory: try container.decodeIfPresent(SyncMemory.self, forKey: .memory)
        )
    }
}

struct SyncMemory: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let cities: String
    let dishes: String
    let theme: String
    let restaurantInformation: String
    let paymentSummary: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        cities: String,
        dishes: String,
        theme: String,
        restaurantInformation: String,
        paymentSummary: String
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.cities = cities
        self.dishes = dishes
        self.theme = theme
        self.restaurantInformation = restaurantInformation
        self.paymentSummary = paymentSummary
    }
}
