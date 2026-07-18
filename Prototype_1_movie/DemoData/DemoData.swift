import Foundation

enum DemoData {
    static let aniket = Participant(
        id: stableID("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"),
        name: "Aniket", initials: "AP", city: "Mumbai",
        address: .init(label: "Home", line: "Bandra West, Mumbai", city: "Mumbai", latitude: 19.0607, longitude: 72.8362),
        isHost: true
    )
    static let aisha = Participant(
        id: stableID("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"),
        name: "Aisha", initials: "AK", city: "Bengaluru",
        address: .init(label: "Home", line: "Indiranagar, Bengaluru", city: "Bengaluru", latitude: 12.9784, longitude: 77.6408),
        isHost: false
    )

    static func item(_ name: String, _ description: String, _ price: Int, _ category: String, veg: Bool = true, spice: Int = 1, symbol: String, tags: Set<String>) -> MenuItem {
        .init(id: UUID(), name: name, description: description, price: price, category: category, isVegetarian: veg, spice: spice, symbol: symbol, tags: tags)
    }

    static let mumbaiMenu: [MenuItem] = [
        item("Paneer Tikka Rice Bowl", "Charred paneer, saffron rice, mint chutney", 329, "Mains", spice: 2, symbol: "takeoutbag.and.cup.and.straw.fill", tags: ["paneer","grill","rice","north-indian"]),
        item("Smoky Dal Makhani", "Slow-cooked black lentils with garlic naan", 289, "Mains", symbol: "frying.pan.fill", tags: ["dal","creamy","north-indian"]),
        item("Masala Lemonade", "Fresh lemon, roasted cumin and mint", 119, "Drinks", symbol: "cup.and.saucer.fill", tags: ["lemon","drink","refreshing"]),
        item("Gulab Jamun Cheesecake", "Rose-scented cheesecake, warm jamun", 219, "Desserts", symbol: "birthday.cake.fill", tags: ["sweet","dessert","gulab-jamun"])
    ]
    static let bengaluruMenu: [MenuItem] = [
        item("Tandoori Paneer Meal", "Clay-oven paneer, jeera rice, green chutney", 319, "Mains", spice: 2, symbol: "takeoutbag.and.cup.and.straw.fill", tags: ["paneer","grill","rice","north-indian"]),
        item("Homestyle Dal & Naan", "Creamy lentils, garlic naan and onion salad", 279, "Mains", symbol: "frying.pan.fill", tags: ["dal","creamy","north-indian"]),
        item("Nimbu Pudina Soda", "Lime, mint and toasted cumin", 109, "Drinks", symbol: "cup.and.saucer.fill", tags: ["lemon","drink","refreshing"]),
        item("Jamun Cream Slice", "Vanilla cream cake with rose and jamun", 209, "Desserts", symbol: "birthday.cake.fill", tags: ["sweet","dessert","gulab-jamun"])
    ]
    static let asianMumbai: [MenuItem] = [
        item("Chilli Garlic Ramen", "Broth, noodles, bok choy and chilli crisp", 369, "Mains", spice: 3, symbol: "takeoutbag.and.cup.and.straw.fill", tags: ["noodles","asian","spicy"]),
        item("Miso Corn Gyoza", "Pan-seared dumplings with miso butter", 249, "Sides", symbol: "frying.pan.fill", tags: ["dumpling","asian","corn"])
    ]
    static let asianBengaluru: [MenuItem] = [
        item("Spicy Miso Noodles", "Noodles, greens, sesame and chilli oil", 359, "Mains", spice: 3, symbol: "takeoutbag.and.cup.and.straw.fill", tags: ["noodles","asian","spicy"]),
        item("Sweet Corn Dimsum", "Steamed dumplings with sesame dip", 239, "Sides", symbol: "frying.pan.fill", tags: ["dumpling","asian","corn"])
    ]

    static let catalogue: [Restaurant] = [
        .init(id: UUID(), name: "Ember & Grain", city: "Mumbai", cuisine: "North Indian", rating: 4.6, priceLevel: 2, preparationMinutes: 24, deliveryMinutes: 18, coordinate: .init(latitude: 19.0680, longitude: 72.8330), menu: mumbaiMenu),
        .init(id: UUID(), name: "Tandoor House", city: "Bengaluru", cuisine: "North Indian", rating: 4.7, priceLevel: 2, preparationMinutes: 22, deliveryMinutes: 21, coordinate: .init(latitude: 12.9718, longitude: 77.6412), menu: bengaluruMenu),
        .init(id: UUID(), name: "Noodle Theory", city: "Mumbai", cuisine: "Asian", rating: 4.5, priceLevel: 2, preparationMinutes: 20, deliveryMinutes: 20, coordinate: .init(latitude: 19.0550, longitude: 72.8300), menu: asianMumbai),
        .init(id: UUID(), name: "Miso Social", city: "Bengaluru", cuisine: "Asian", rating: 4.4, priceLevel: 2, preparationMinutes: 23, deliveryMinutes: 18, coordinate: .init(latitude: 12.9820, longitude: 77.6350), menu: asianBengaluru),
        .init(id: UUID(), name: "Zomato Kitchen", city: "Mumbai", cuisine: "Multi-cuisine", rating: 4.6, priceLevel: 2, preparationMinutes: 21, deliveryMinutes: 18, coordinate: .init(latitude: 19.0615, longitude: 72.8401), menu: mumbaiMenu + asianMumbai),
        .init(id: UUID(), name: "Zomato Kitchen", city: "Bengaluru", cuisine: "Multi-cuisine", rating: 4.6, priceLevel: 2, preparationMinutes: 22, deliveryMinutes: 19, coordinate: .init(latitude: 12.9801, longitude: 77.6382), menu: bengaluruMenu + asianBengaluru)
    ]

    private static func stableID(_ value: String) -> UUID {
        guard let id = UUID(uuidString: value) else {
            preconditionFailure("Invalid demo UUID: \(value)")
        }
        return id
    }
}
