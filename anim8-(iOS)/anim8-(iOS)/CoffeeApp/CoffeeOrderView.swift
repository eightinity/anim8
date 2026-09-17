import SwiftUI

// MARK: - Order / Checkout

struct CoffeeOrderView: View {
    let item: CoffeeItem
    let size: CoffeeSize
    var onBack: () -> Void = {}
    var onPlaceOrder: () -> Void = {}

    @State private var quantity: Int
    @State private var deliveryMethod: DeliveryMethod = .deliver
    @State private var paymentMethod: PaymentMethod = .card
    @State private var appeared = false
    @State private var orderPlaced = false
    @State private var placingOrder = false

    init(item: CoffeeItem, size: CoffeeSize, quantity: Int = 1, onBack: @escaping () -> Void = {}, onPlaceOrder: @escaping () -> Void = {}) {
        self.item = item
        self.size = size
        self._quantity = State(initialValue: quantity)
        self.onBack = onBack
        self.onPlaceOrder = onPlaceOrder
    }

    private let deliveryFee = 1.50
    private let discount = 2.00

    private var subtotal: Double { item.price(for: size) * Double(quantity) }
    private var total: Double { max(subtotal + deliveryFee - discount, 0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoffeeSpacing.lg) {
                header
                deliveryToggle
                addressCard
                orderItemRow
                priceSummary
            }
            .padding(.horizontal, CoffeeSpacing.lg)
            .padding(.top, CoffeeSpacing.md)
            .padding(.bottom, 150)
        }
        .background(CoffeeColor.background)
        .overlay(alignment: .bottom) { orderBar }
        .onAppear {
            CoffeeHaptics.prepare()
            withAnimation(CoffeeSpring.stagger) { appeared = true }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                CoffeeHaptics.tap()
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CoffeeColor.ink)
                    .frame(width: 40, height: 40)
                    .background(CoffeeColor.well, in: Circle())
            }
            .buttonStyle(.plain)
            .coffeePressable()

            Spacer()

            Text("Checkout")
                .font(.sora(.semibold, 18))
                .foregroundStyle(CoffeeColor.ink)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Deliver / Pickup

    private var deliveryToggle: some View {
        HStack(spacing: 4) {
            ForEach(DeliveryMethod.allCases) { method in
                let isSelected = deliveryMethod == method
                Button {
                    CoffeeHaptics.tick()
                    withAnimation(CoffeeSpring.snap) { deliveryMethod = method }
                } label: {
                    Text(method.rawValue)
                        .font(.sora(.semibold, 14))
                        .foregroundStyle(isSelected ? .white : CoffeeColor.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: CoffeeRadius.sm, style: .continuous)
                                .fill(isSelected ? CoffeeColor.espresso : Color.clear)
                        )
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                        .animation(CoffeeSpring.bouncy, value: isSelected)
                }
                .buttonStyle(.plain)
                .coffeePressable(scale: 0.95)
            }
        }
        .padding(4)
        .background(CoffeeColor.well, in: RoundedRectangle(cornerRadius: CoffeeRadius.sm + 4, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: Address

    private var addressCard: some View {
        HStack(spacing: CoffeeSpacing.md) {
            Image(systemName: deliveryMethod == .deliver ? "location.fill" : "storefront.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(CoffeeColor.espresso, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(deliveryMethod == .deliver ? "Home" : "Nearest Store")
                    .font(.sora(.semibold, 15))
                    .foregroundStyle(CoffeeColor.ink)
                Text(deliveryMethod == .deliver ? "2118 Thornridge Cir, VA 22181" : "5th Avenue Coffee Bar, 0.4 mi away")
                    .font(.sora(.regular, 13))
                    .foregroundStyle(CoffeeColor.muted)
                    .lineLimit(1)
            }

            Spacer()

            Text("Change")
                .font(.sora(.semibold, 13))
                .foregroundStyle(CoffeeColor.espresso)
        }
        .padding(CoffeeSpacing.md)
        .background(CoffeeColor.surface, in: RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(CoffeeSpring.snap, value: deliveryMethod)
    }

    // MARK: Ordered item

    private var orderItemRow: some View {
        HStack(spacing: CoffeeSpacing.md) {
            Image(item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: CoffeeRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.sora(.semibold, 15))
                    .foregroundStyle(CoffeeColor.ink)
                Text("Size \(size.rawValue)")
                    .font(.sora(.regular, 13))
                    .foregroundStyle(CoffeeColor.muted)
            }

            Spacer()

            HStack(spacing: CoffeeSpacing.sm) {
                stepperButton(system: "minus") {
                    guard quantity > 1 else { return }
                    CoffeeHaptics.tick()
                    withAnimation(CoffeeSpring.quick) { quantity -= 1 }
                }
                Text("\(quantity)")
                    .font(.sora(.semibold, 15))
                    .foregroundStyle(CoffeeColor.ink)
                    .frame(minWidth: 16)
                    .contentTransition(.numericText())
                stepperButton(system: "plus") {
                    guard quantity < 9 else { return }
                    CoffeeHaptics.tick()
                    withAnimation(CoffeeSpring.quick) { quantity += 1 }
                }
            }
        }
        .padding(CoffeeSpacing.md)
        .background(CoffeeColor.surface, in: RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private func stepperButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CoffeeColor.espresso)
                .frame(width: 26, height: 26)
                .background(CoffeeColor.well, in: Circle())
        }
        .buttonStyle(.plain)
        .coffeePressable()
    }

    // MARK: Price summary

    private var priceSummary: some View {
        VStack(spacing: CoffeeSpacing.sm) {
            priceRow("Subtotal", value: subtotal)
            priceRow("Delivery Fee", value: deliveryFee)
            priceRow("Discount", value: -discount, valueColor: CoffeeColor.success)

            Divider().padding(.vertical, 4)

            HStack {
                Text("Total")
                    .font(.sora(.semibold, 16))
                    .foregroundStyle(CoffeeColor.ink)
                Spacer()
                Text("$\(total, specifier: "%.2f")")
                    .font(.sora(.bold, 18))
                    .foregroundStyle(CoffeeColor.ink)
                    .contentTransition(.numericText())
            }

            paymentSelector
        }
        .padding(CoffeeSpacing.md)
        .background(CoffeeColor.surface, in: RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(CoffeeSpring.snap, value: quantity)
    }

    private func priceRow(_ label: String, value: Double, valueColor: Color = CoffeeColor.muted) -> some View {
        HStack {
            Text(label)
                .font(.sora(.regular, 14))
                .foregroundStyle(CoffeeColor.muted)
            Spacer()
            Text("\(value < 0 ? "-" : "")$\(abs(value), specifier: "%.2f")")
                .font(.sora(.medium, 14))
                .foregroundStyle(valueColor)
                .contentTransition(.numericText())
        }
    }

    private var paymentSelector: some View {
        VStack(alignment: .leading, spacing: CoffeeSpacing.sm) {
            Text("Payment Method")
                .font(.sora(.semibold, 14))
                .foregroundStyle(CoffeeColor.ink)
                .padding(.top, CoffeeSpacing.sm)

            HStack(spacing: CoffeeSpacing.sm) {
                ForEach(PaymentMethod.allCases) { method in
                    let isSelected = paymentMethod == method
                    Button {
                        CoffeeHaptics.tick()
                        withAnimation(CoffeeSpring.snap) { paymentMethod = method }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: method.symbol)
                                .font(.system(size: 16))
                            Text(method.rawValue)
                                .font(.sora(.medium, 11))
                        }
                        .foregroundStyle(isSelected ? .white : CoffeeColor.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            RoundedRectangle(cornerRadius: CoffeeRadius.sm, style: .continuous)
                                .fill(isSelected ? CoffeeColor.espresso : CoffeeColor.well)
                        )
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(CoffeeSpring.bouncy, value: isSelected)
                    }
                    .buttonStyle(.plain)
                    .coffeePressable(scale: 0.94)
                }
            }
        }
    }

    // MARK: Order bar

    private var orderBar: some View {
        Button {
            guard !placingOrder else { return }
            placingOrder = true
            CoffeeHaptics.commit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                CoffeeHaptics.success()
                withAnimation(CoffeeSpring.bouncy) { orderPlaced = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    onPlaceOrder()
                }
            }
        } label: {
            HStack(spacing: 10) {
                if placingOrder && !orderPlaced {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if orderPlaced {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .symbolEffect(.bounce, value: orderPlaced)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(orderPlaced ? "Order Placed!" : "Place Order · $\(total, specifier: "%.2f")")
                    .font(.sora(.semibold, 16))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(orderPlaced ? CoffeeColor.success : CoffeeColor.espresso, in: Capsule())
            .scaleEffect(orderPlaced ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .coffeePressable(scale: 0.96)
        .animation(CoffeeSpring.bouncy, value: orderPlaced)
        .disabled(placingOrder)
        .padding(.horizontal, CoffeeSpacing.lg)
        .padding(.top, CoffeeSpacing.md)
        .padding(.bottom, CoffeeSpacing.lg)
        .background(
            CoffeeColor.surface
                .clipShape(RoundedRectangle(cornerRadius: CoffeeRadius.lg, style: .continuous))
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    CoffeeOrderView(item: sampleCoffeeItems[0], size: .medium)
}
