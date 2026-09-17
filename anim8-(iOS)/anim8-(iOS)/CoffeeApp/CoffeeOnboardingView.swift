import SwiftUI

// MARK: - Onboarding

struct CoffeeOnboardingView: View {
    var onGetStarted: () -> Void = {}

    @State private var heroAppeared = false
    @State private var contentAppeared = false
    @State private var arrowNudge = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                heroImage(width: geo.size.width, height: geo.size.height)

                gradientScrim

                content
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            CoffeeHaptics.prepare()
            withAnimation(.easeOut(duration: 1.1)) {
                heroAppeared = true
            }
            withAnimation(CoffeeSpring.gentle.delay(0.35)) {
                contentAppeared = true
            }
        }
    }

    private func heroImage(width: CGFloat, height: CGFloat) -> some View {
        Image("CoffeeOnboardingHero")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .scaleEffect(heroAppeared ? 1.0 : 1.12)
            .opacity(heroAppeared ? 1.0 : 0.0)
            .clipped()
    }

    private var gradientScrim: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.05), location: 0.0),
                .init(color: .black.opacity(0.15), location: 0.35),
                .init(color: .black.opacity(0.55), location: 0.62),
                .init(color: .black.opacity(0.92), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: CoffeeSpacing.md) {
            Text("BREW YOUR DAY")
                .font(.sora(.semibold, 13))
                .tracking(3)
                .foregroundStyle(CoffeeColor.amber)

            Text("Great coffee,\ndelivered to your door.")
                .font(.sora(.bold, 34))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("Handpicked beans, brewed to order, and on your doorstep in minutes. Your perfect cup is one tap away.")
                .font(.sora(.regular, 15))
                .foregroundStyle(.white.opacity(0.72))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            getStartedButton
                .padding(.top, CoffeeSpacing.sm)
        }
        .padding(.horizontal, CoffeeSpacing.lg)
        .padding(.bottom, CoffeeSpacing.xl)
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 24)
    }

    private var getStartedButton: some View {
        Button {
            CoffeeHaptics.commit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                onGetStarted()
            }
        } label: {
            HStack(spacing: CoffeeSpacing.sm) {
                Text("Get Started")
                    .font(.sora(.semibold, 16))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .offset(x: arrowNudge ? 3 : 0)
            }
            .foregroundStyle(CoffeeColor.espressoDeep)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white, in: Capsule())
        }
        .buttonStyle(.plain)
        .coffeePressable(scale: 0.94)
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.55)) { arrowNudge = true }
                try? await Task.sleep(for: .seconds(0.55))
                withAnimation(.easeInOut(duration: 0.55)) { arrowNudge = false }
                try? await Task.sleep(for: .seconds(1.8))
            }
        }
    }
}

#Preview {
    CoffeeOnboardingView()
}
