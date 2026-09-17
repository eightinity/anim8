import Foundation

// MARK: - Category

enum CoffeeCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case hot = "Hot"
    case iced = "Iced"
    case specialty = "Specialty"

    var id: String { rawValue }
}

// MARK: - Size

enum CoffeeSize: String, CaseIterable, Identifiable {
    case small = "S"
    case medium = "M"
    case large = "L"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var priceDelta: Double {
        switch self {
        case .small: return 0
        case .medium: return 0.75
        case .large: return 1.50
        }
    }
}

// MARK: - Coffee Item

struct CoffeeItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let imageName: String
    let basePrice: Double
    let rating: Double
    let ratingCount: Int
    let description: String
    let category: CoffeeCategory

    func price(for size: CoffeeSize) -> Double {
        basePrice + size.priceDelta
    }
}

// MARK: - Sample Data

let sampleCoffeeItems: [CoffeeItem] = [
    CoffeeItem(
        name: "Cappuccino",
        subtitle: "with Cinnamon",
        imageName: "CoffeeCappuccino",
        basePrice: 4.25,
        rating: 4.8,
        ratingCount: 236,
        description: "A rich double shot of espresso balanced with steamed milk and a deep layer of silky microfoam, finished with a dusting of cinnamon for warmth.",
        category: .hot
    ),
    CoffeeItem(
        name: "Caffè Latte",
        subtitle: "with Latte Art",
        imageName: "CoffeeLatte",
        basePrice: 4.00,
        rating: 4.9,
        ratingCount: 412,
        description: "Smooth espresso poured into velvety steamed milk, topped with a delicate rosetta. Mellow, comforting, and endlessly customizable.",
        category: .hot
    ),
    CoffeeItem(
        name: "Flat White",
        subtitle: "Double Shot",
        imageName: "CoffeeFlatWhite",
        basePrice: 4.35,
        rating: 4.7,
        ratingCount: 189,
        description: "A stronger, silkier cousin of the latte — two shots of espresso with a thin layer of micro-foamed milk for a bold, velvety finish.",
        category: .hot
    ),
    CoffeeItem(
        name: "Mocha",
        subtitle: "Dark Chocolate",
        imageName: "CoffeeMocha",
        basePrice: 4.60,
        rating: 4.6,
        ratingCount: 154,
        description: "Espresso meets rich dark chocolate and steamed milk, finished with a light cocoa dusting. Sweet, indulgent, and a little dangerous.",
        category: .specialty
    ),
    CoffeeItem(
        name: "Macchiato",
        subtitle: "Caramel Layer",
        imageName: "CoffeeMacchiato",
        basePrice: 4.50,
        rating: 4.5,
        ratingCount: 98,
        description: "Espresso 'stained' with a touch of foam and a ribbon of caramel, served in a glass so you can see every layer.",
        category: .iced
    ),
    CoffeeItem(
        name: "Americano",
        subtitle: "Classic Black",
        imageName: "CoffeeAmericano",
        basePrice: 3.50,
        rating: 4.4,
        ratingCount: 267,
        description: "Espresso shots topped with hot water for a lighter body while keeping the same rich, full-bodied espresso flavor.",
        category: .hot
    ),
]

// MARK: - Cart

struct CartLine: Identifiable {
    let id = UUID()
    let item: CoffeeItem
    var size: CoffeeSize
    var quantity: Int

    var lineTotal: Double {
        item.price(for: size) * Double(quantity)
    }
}

// MARK: - Delivery

enum DeliveryMethod: String, CaseIterable, Identifiable {
    case deliver = "Deliver"
    case pickup = "Pick Up"

    var id: String { rawValue }
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case card = "Credit Card"
    case cash = "Cash"
    case wallet = "Wallet"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .card: return "creditcard.fill"
        case .cash: return "banknote.fill"
        case .wallet: return "wallet.pass.fill"
        }
    }
}

// MARK: - Courier

struct Courier {
    let name: String
    let vehicle: String
    let rating: Double
    let initials: String
}

let sampleCourier = Courier(name: "Alex Morgan", vehicle: "Honda · Red Scooter", rating: 4.9, initials: "AM")

// MARK: - Delivery status

enum DeliveryStatus: Int, CaseIterable, Identifiable {
    case preparing
    case onTheWay
    case arriving
    case delivered

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .preparing: return "Preparing your order"
        case .onTheWay: return "Courier is on the way"
        case .arriving: return "Almost there"
        case .delivered: return "Delivered"
        }
    }

    var subtitle: String {
        switch self {
        case .preparing: return "Your barista is crafting your order"
        case .onTheWay: return "Your order will arrive soon"
        case .arriving: return "Your courier is just around the corner"
        case .delivered: return "Enjoy your coffee!"
        }
    }
}
