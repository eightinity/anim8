import SwiftUI

// MARK: - Home

struct CoffeeHomeView: View {
    var onSelectItem: (CoffeeItem) -> Void = { _ in }
    var onCheckout: () -> Void = {}

    @State private var searchText = ""
    @State private var selectedCategory: CoffeeCategory = .all
    @State private var appeared = false
    @State private var cartCount = 0
    @State private var bellRing = false
    @State private var toastItemName: String?
    @State private var toastToken = UUID()

    private var filteredItems: [CoffeeItem] {
        sampleCoffeeItems.filter { item in
            (selectedCategory == .all || item.category == selectedCategory) &&
            (searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    private let columns = [GridItem(.flexible(), spacing: CoffeeSpacing.md), GridItem(.flexible(), spacing: CoffeeSpacing.md)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoffeeSpacing.lg) {
                header
                    .padding(.horizontal, CoffeeSpacing.lg)

                searchBar
                    .padding(.horizontal, CoffeeSpacing.lg)

                promoBanner
                    .padding(.horizontal, CoffeeSpacing.lg)

                categoryPills

                itemGrid
                    .padding(.horizontal, CoffeeSpacing.lg)
            }
            .padding(.top, CoffeeSpacing.md)
            .padding(.bottom, CoffeeSpacing.xl)
        }
        .background(CoffeeColor.background)
        .overlay(alignment: .top) { addedToCartToast }
        .onAppear {
            CoffeeHaptics.prepare()
            withAnimation(CoffeeSpring.stagger) { appeared = true }
        }
    }

    // MARK: Toast

    private var addedToCartToast: some View {
        Group {
            if let name = toastItemName {
                HStack(spacing: CoffeeSpacing.sm) {
                    ZStack {
                        Circle().fill(CoffeeColor.success).frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("\(name) added to cart")
                        .font(.sora(.medium, 13))
                        .foregroundStyle(CoffeeColor.ink)
                        .lineLimit(1)
                }
                .padding(.horizontal, CoffeeSpacing.md)
                .frame(height: 44)
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
                .padding(.top, CoffeeSpacing.sm)
                .transition(.coffeeWidthPop)
            }
        }
        .animation(CoffeeSpring.pop, value: toastItemName)
    }

    private func showAddedToast(for name: String) {
        let token = UUID()
        toastToken = token
        toastItemName = name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if toastToken == token {
                toastItemName = nil
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DELIVER TO")
                    .font(.sora(.semibold, 11))
                    .tracking(2)
                    .foregroundStyle(CoffeeColor.muted)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(CoffeeColor.espresso)
                    Text("2118 Thornridge, VA")
                        .font(.sora(.semibold, 16))
                        .foregroundStyle(CoffeeColor.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CoffeeColor.muted)
                }
            }

            Spacer()

            HStack(spacing: CoffeeSpacing.sm) {
                cartButton

                Button {
                    CoffeeHaptics.tap()
                    withAnimation(CoffeeSpring.bouncy) { bellRing.toggle() }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(CoffeeColor.well)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(CoffeeColor.espresso)
                                    .symbolEffect(.wiggle, value: bellRing)
                            )
                        Circle()
                            .fill(CoffeeColor.danger)
                            .frame(width: 9, height: 9)
                            .offset(x: -2, y: 2)
                    }
                }
                .buttonStyle(.plain)
                .coffeePressable()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -12)
    }

    private var cartButton: some View {
        Button {
            CoffeeHaptics.tap()
        } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(CoffeeColor.well)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(CoffeeColor.espresso)
                            .symbolEffect(.bounce, value: cartCount)
                    )

                if cartCount > 0 {
                    Text("\(cartCount)")
                        .font(.sora(.bold, 11))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(CoffeeColor.espresso, in: Circle())
                        .contentTransition(.numericText())
                        .offset(x: 4, y: -4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .coffeePressable()
        .animation(CoffeeSpring.pop, value: cartCount)
    }

    // MARK: Search

    private var searchBar: some View {
        HStack(spacing: CoffeeSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CoffeeColor.muted)
            TextField("Search coffee...", text: $searchText)
                .font(.sora(.regular, 15))
                .foregroundStyle(CoffeeColor.ink)

            Divider().frame(height: 22)

            Image(systemName: "slider.horizontal.3")
                .foregroundStyle(CoffeeColor.espresso)
        }
        .padding(.horizontal, CoffeeSpacing.md)
        .frame(height: 52)
        .background(CoffeeColor.surface, in: RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // MARK: Promo banner

    private var promoBanner: some View {
        ZStack(alignment: .leading) {
            Image("CoffeePromoBanner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: CoffeeRadius.lg, style: .continuous))

            LinearGradient(
                colors: [.black.opacity(0.62), .black.opacity(0.08)],
                startPoint: .leading, endPoint: .trailing
            )
            .clipShape(RoundedRectangle(cornerRadius: CoffeeRadius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("PROMO 30%")
                    .font(.sora(.semibold, 11))
                    .tracking(2)
                    .foregroundStyle(CoffeeColor.amber)
                Text("Happy Coffee\nDay Discount!")
                    .font(.sora(.bold, 19))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
            }
            .padding(CoffeeSpacing.lg)
        }
        .frame(height: 140)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.96)
    }

    // MARK: Category pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CoffeeSpacing.sm) {
                ForEach(CoffeeCategory.allCases) { category in
                    CategoryPill(category: category, isSelected: selectedCategory == category) {
                        CoffeeHaptics.tick()
                        withAnimation(CoffeeSpring.snap) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, CoffeeSpacing.lg)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Grid

    private var itemGrid: some View {
        LazyVGrid(columns: columns, spacing: CoffeeSpacing.md) {
            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                CoffeeItemCard(item: item) {
                    onSelectItem(item)
                } onAdd: {
                    cartCount += 1
                    showAddedToast(for: item.name)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(CoffeeSpring.stagger.delay(Double(index) * 0.05), value: appeared)
            }
        }
    }
}

// MARK: - Category Pill

private struct CategoryPill: View {
    let category: CoffeeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.sora(.medium, 14))
                .foregroundStyle(isSelected ? .white : CoffeeColor.muted)
                .padding(.horizontal, CoffeeSpacing.md)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isSelected ? CoffeeColor.espresso : CoffeeColor.well)
                )
                .scaleEffect(isSelected ? 1.06 : 1.0)
                .animation(CoffeeSpring.bouncy, value: isSelected)
        }
        .buttonStyle(.plain)
        .coffeePressable(scale: 0.93)
    }
}

// MARK: - Item Card

private struct CoffeeItemCard: View {
    let item: CoffeeItem
    let onTap: () -> Void
    let onAdd: () -> Void

    @State private var justAdded = false

    var body: some View {
        VStack(alignment: .leading, spacing: CoffeeSpacing.sm) {
            Image(item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 108)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: CoffeeRadius.sm, style: .continuous))

            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(CoffeeColor.amber)
                Text(String(format: "%.1f", item.rating))
                    .font(.sora(.medium, 12))
                    .foregroundStyle(CoffeeColor.muted)
            }

            Text(item.name)
                .font(.sora(.semibold, 15))
                .foregroundStyle(CoffeeColor.ink)
                .lineLimit(1)

            HStack {
                Text("$\(item.basePrice, specifier: "%.2f")")
                    .font(.sora(.bold, 16))
                    .foregroundStyle(CoffeeColor.ink)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    CoffeeHaptics.commit()
                    withAnimation(CoffeeSpring.bouncy) { justAdded = true }
                    onAdd()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(CoffeeSpring.snap) { justAdded = false }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(CoffeeColor.espresso)
                            .frame(width: 30, height: 30)
                        Image(systemName: justAdded ? "checkmark" : "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .scaleEffect(justAdded ? 1.12 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(CoffeeSpacing.sm)
        .background(CoffeeColor.surface, in: RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
        .onTapGesture { onTap() }
        .coffeePressable(scale: 0.97)
    }
}

#Preview {
    CoffeeHomeView()
}
