import SwiftUI

// MARK: - Detail

struct CoffeeDetailView: View {
    let item: CoffeeItem
    var onBack: () -> Void = {}
    var onBuy: (CoffeeSize, Int) -> Void = { _, _ in }

    @State private var selectedSize: CoffeeSize = .medium
    @State private var quantity = 1
    @State private var isFavorite = false
    @State private var showFullDescription = false
    @State private var appeared = false

    private var currentPrice: Double {
        item.price(for: selectedSize) * Double(quantity)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection

                VStack(alignment: .leading, spacing: CoffeeSpacing.lg) {
                    titleRow
                    descriptionSection
                    sizeSection
                    quantitySection
                }
                .padding(.horizontal, CoffeeSpacing.lg)
                .padding(.top, CoffeeSpacing.lg)
                .padding(.bottom, 140)
            }
        }
        .background(CoffeeColor.background)
        .overlay(alignment: .bottom) { buyBar }
        .onAppear {
            CoffeeHaptics.prepare()
            withAnimation(CoffeeSpring.stagger) { appeared = true }
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        ZStack(alignment: .top) {
            Image(item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 340)
                .clipped()
                .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [.black.opacity(0.35), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 120)

            HStack {
                circleButton(system: "chevron.left") {
                    CoffeeHaptics.tap()
                    onBack()
                }
                Spacer()
                favoriteButton
            }
            .padding(.horizontal, CoffeeSpacing.lg)
            .padding(.top, CoffeeSpacing.md)
        }
        .frame(height: 340)
        .opacity(appeared ? 1 : 0)
    }

    private func circleButton(system: String, tint: Color = CoffeeColor.espresso, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
        }
        .buttonStyle(.plain)
        .coffeePressable()
    }

    private var favoriteButton: some View {
        Button {
            CoffeeHaptics.tick()
            withAnimation(CoffeeSpring.bouncy) { isFavorite.toggle() }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFavorite ? CoffeeColor.danger : CoffeeColor.espresso)
                .symbolEffect(.bounce, value: isFavorite)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
        }
        .buttonStyle(.plain)
        .coffeePressable()
    }

    // MARK: Title

    private var titleRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.sora(.bold, 24))
                    .foregroundStyle(CoffeeColor.ink)
                Text(item.subtitle)
                    .font(.sora(.regular, 14))
                    .foregroundStyle(CoffeeColor.muted)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(CoffeeColor.amber)
                Text(String(format: "%.1f", item.rating))
                    .font(.sora(.semibold, 14))
                    .foregroundStyle(CoffeeColor.ink)
                Text("(\(item.ratingCount))")
                    .font(.sora(.regular, 13))
                    .foregroundStyle(CoffeeColor.muted)
            }
            .padding(.horizontal, CoffeeSpacing.sm)
            .padding(.vertical, 8)
            .background(CoffeeColor.well, in: Capsule())
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    // MARK: Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.description)
                .font(.sora(.regular, 14))
                .foregroundStyle(CoffeeColor.muted)
                .lineSpacing(4)
                .lineLimit(showFullDescription ? nil : 2)

            Button {
                withAnimation(CoffeeSpring.gentle) { showFullDescription.toggle() }
            } label: {
                Text(showFullDescription ? "Read Less" : "Read More")
                    .font(.sora(.semibold, 13))
                    .foregroundStyle(CoffeeColor.espresso)
            }
            .buttonStyle(.plain)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    // MARK: Size

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: CoffeeSpacing.sm) {
            Text("Size")
                .font(.sora(.semibold, 16))
                .foregroundStyle(CoffeeColor.ink)

            HStack(spacing: CoffeeSpacing.sm) {
                ForEach(CoffeeSize.allCases) { size in
                    sizeChip(size)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    private func sizeChip(_ size: CoffeeSize) -> some View {
        let isSelected = selectedSize == size
        return Button {
            CoffeeHaptics.tick()
            withAnimation(CoffeeSpring.snap) { selectedSize = size }
        } label: {
            VStack(spacing: 2) {
                Text(size.rawValue)
                    .font(.sora(.bold, 16))
                Text(size.label)
                    .font(.sora(.regular, 11))
            }
            .foregroundStyle(isSelected ? .white : CoffeeColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: CoffeeRadius.sm, style: .continuous)
                    .fill(isSelected ? CoffeeColor.espresso : CoffeeColor.surface)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(CoffeeSpring.bouncy, value: isSelected)
        }
        .buttonStyle(.plain)
        .coffeePressable(scale: 0.94)
    }

    // MARK: Quantity

    private var quantitySection: some View {
        HStack {
            Text("Quantity")
                .font(.sora(.semibold, 16))
                .foregroundStyle(CoffeeColor.ink)

            Spacer()

            HStack(spacing: CoffeeSpacing.md) {
                stepperButton(system: "minus") {
                    guard quantity > 1 else { return }
                    CoffeeHaptics.tick()
                    withAnimation(CoffeeSpring.quick) { quantity -= 1 }
                }

                Text("\(quantity)")
                    .font(.sora(.semibold, 16))
                    .foregroundStyle(CoffeeColor.ink)
                    .frame(minWidth: 20)
                    .contentTransition(.numericText())

                stepperButton(system: "plus") {
                    guard quantity < 9 else { return }
                    CoffeeHaptics.tick()
                    withAnimation(CoffeeSpring.quick) { quantity += 1 }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    private func stepperButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(CoffeeColor.espresso)
                .frame(width: 32, height: 32)
                .background(CoffeeColor.well, in: Circle())
        }
        .buttonStyle(.plain)
        .coffeePressable()
    }

    // MARK: Buy bar

    private var buyBar: some View {
        HStack(spacing: CoffeeSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Price")
                    .font(.sora(.regular, 12))
                    .foregroundStyle(CoffeeColor.muted)
                Text("$\(currentPrice, specifier: "%.2f")")
                    .font(.sora(.bold, 20))
                    .foregroundStyle(CoffeeColor.ink)
                    .contentTransition(.numericText())
            }

            Spacer()

            Button {
                CoffeeHaptics.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onBuy(selectedSize, quantity)
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Buy Now")
                        .font(.sora(.semibold, 16))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, CoffeeSpacing.xl)
                .frame(height: 56)
                .background(CoffeeColor.espresso, in: Capsule())
            }
            .buttonStyle(.plain)
            .coffeePressable(scale: 0.93)
        }
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
    CoffeeDetailView(item: sampleCoffeeItems[0])
}
