import Foundation

protocol RestaurantCatalogueService: Sendable {
    func restaurants(in city: String) async -> [Restaurant]
}

struct MockRestaurantCatalogueService: RestaurantCatalogueService {
    func restaurants(in city: String) async -> [Restaurant] {
        DemoData.catalogue.filter { $0.city == city }
    }
}

protocol RestaurantMatchingService: Sendable {
    func matches(host: [Restaurant], partner: [Restaurant]) async -> [RestaurantPair]
}

struct DeterministicRestaurantMatchingService: RestaurantMatchingService {
    func matches(host: [Restaurant], partner: [Restaurant]) async -> [RestaurantPair] {
        host.flatMap { first in
            partner.map { second in
                let similarity = menuSimilarity(first.menu, second.menu)
                let price = first.priceLevel == second.priceLevel
                let prep = abs(first.preparationMinutes - second.preparationMinutes) <= 5
                let difference = abs((first.preparationMinutes + first.deliveryMinutes) - (second.preparationMinutes + second.deliveryMinutes))
                let availability = first.name == second.name ? 20 : 13
                let total = min(99, availability + Int(Double(similarity) * 0.45) + (price ? 10 : 3) + (prep ? 8 : 2) + max(0, 8 - difference) + Int(min(first.rating, second.rating) * 2))
                return RestaurantPair(
                    hostRestaurant: first,
                    partnerRestaurant: second,
                    score: .init(total: total, menuSimilarity: similarity, predictedDifference: difference, priceCompatible: price, prepCompatible: prep),
                    theme: theme(for: first, second)
                )
            }
        }.sorted { $0.score.total > $1.score.total }
    }

    private func menuSimilarity(_ lhs: [MenuItem], _ rhs: [MenuItem]) -> Int {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        var bestScores: [Double] = []
        for item in lhs {
            let best = rhs.map { other -> Double in
                let union = item.tags.union(other.tags).count
                guard union > 0 else { return 0 }
                return Double(item.tags.intersection(other.tags).count) / Double(union)
            }.max() ?? 0
            bestScores.append(best)
        }
        return Int((bestScores.reduce(0, +) / Double(bestScores.count) * 100).rounded())
    }

    private func theme(for first: Restaurant, _ second: Restaurant) -> String {
        if first.cuisine == "North Indian" && second.cuisine == "North Indian" { return "North Indian Grill Night" }
        if first.cuisine == "Asian" && second.cuisine == "Asian" { return "Cosy Noodle Night" }
        return "Comfort Food Together"
    }
}

protocol LinkedOrderService: Sendable {
    func submit(table: SyncTable) async throws -> [LinkedOrder]
}

enum OrderError: Error { case notReady, emptyCart, unavailable }

struct MockLinkedOrderService: LinkedOrderService {
    func submit(table: SyncTable) async throws -> [LinkedOrder] {
        guard table.hostReady, table.partnerReady else { throw OrderError.notReady }
        guard !table.hostCart.items.isEmpty, !table.partnerCart.items.isEmpty else { throw OrderError.emptyCart }
        guard let pair = table.selectedPair else { throw OrderError.unavailable }
        return [
            .init(id: "ZST-MUM-4821", ownerID: table.host.id, restaurantName: pair.hostRestaurant.name, address: table.host.address, total: finalAmount(for: table.hostCart, delivery: 39), status: .authorized, estimate: .init(minutes: 42, window: "8:04–8:08 PM"), paymentAuthorized: true),
            .init(id: "ZST-BLR-7390", ownerID: table.partner.id, restaurantName: pair.partnerRestaurant.name, address: table.partner.address, total: finalAmount(for: table.partnerCart, delivery: 35), status: .authorized, estimate: .init(minutes: 45, window: "8:06–8:10 PM"), paymentAuthorized: true)
        ]
    }

    private func finalAmount(for cart: Cart, delivery: Int) -> Int {
        cart.total + delivery + Int((Double(cart.total) * 0.05).rounded())
    }
}

protocol MenuTwinService: Sendable {
    func profile(for item: MenuItem, counterpart: MenuItem) async -> MenuTwinProfile
}

struct DeterministicMenuTwinService: MenuTwinService {
    func profile(for item: MenuItem, counterpart: MenuItem) async -> MenuTwinProfile {
        let shared = item.tags.intersection(counterpart.tags)
        return .init(
            canonicalDishType: shared.contains("paneer") ? "Grilled paneer meal" : (shared.contains("noodles") ? "Spiced noodle bowl" : item.category),
            cuisine: shared.contains("north-indian") ? "North Indian" : (shared.contains("asian") ? "Asian" : "Contemporary"),
            mealCategory: item.category,
            isVegetarian: item.isVegetarian && counterpart.isVegetarian,
            flavorProfile: shared.sorted(),
            spiceCategory: max(item.spice, counterpart.spice) >= 3 ? "Hot" : "Medium",
            cookingStyle: shared.contains("grill") ? "Char-grilled" : "Prepared fresh",
            suitableCounterpart: counterpart.name
        )
    }
}
