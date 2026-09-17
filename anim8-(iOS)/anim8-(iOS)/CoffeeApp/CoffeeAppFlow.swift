import SwiftUI

// MARK: - Navigation path

private enum CoffeeRoute: Hashable {
    case detail(CoffeeItem)
    case order(CoffeeItem, CoffeeSize, Int)
    case tracking
}

// MARK: - Flow

/// Top-level flow wiring the coffee ordering screens together:
/// Onboarding → Home → Detail → Checkout → Tracking.
struct CoffeeAppFlow: View {
    @State private var showOnboarding = true
    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                CoffeeHomeView { item in
                    path.append(CoffeeRoute.detail(item))
                } onCheckout: {
                    path.append(CoffeeRoute.tracking)
                }
                .navigationDestination(for: CoffeeRoute.self) { route in
                    switch route {
                    case .detail(let item):
                        CoffeeDetailView(item: item) {
                            path.removeLast()
                        } onBuy: { size, quantity in
                            path.append(CoffeeRoute.order(item, size, quantity))
                        }
                        .navigationBarBackButtonHidden()

                    case .order(let item, let size, let quantity):
                        CoffeeOrderView(item: item, size: size, quantity: quantity) {
                            path.removeLast()
                        } onPlaceOrder: {
                            path.append(CoffeeRoute.tracking)
                        }
                        .navigationBarBackButtonHidden()

                    case .tracking:
                        CoffeeTrackingView {
                            path = NavigationPath()
                        }
                        .navigationBarBackButtonHidden()
                    }
                }
            }
            .opacity(showOnboarding ? 0 : 1)
            .scaleEffect(showOnboarding ? 1.04 : 1.0)

            if showOnboarding {
                CoffeeOnboardingView {
                    CoffeeHaptics.thud()
                    withAnimation(CoffeeSpring.gentle) {
                        showOnboarding = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .opacity.combined(with: .scale(scale: 1.08))
                ))
                .zIndex(1)
            }
        }
    }
}

#Preview {
    CoffeeAppFlow()
}
