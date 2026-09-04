//
//  FootballCardPack.swift
//  anim8-(iOS)
//
//  Card Pack Opening animation — swipe up to tear open a foil pack,
//  cards reveal one by one with 3D flip, shimmer on rare cards,
//  animated stat rings, and haptic feedback throughout.
//

import SwiftUI
import UIKit

// MARK: - Model

enum CardTier: String {
    case gold = "GOLD"
    case silver = "SILVER"
    case bronze = "BRONZE"

    
    var color: Color {
        switch self {
        case .gold:   return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        }
    }

    var shimmerColors: [Color] {
        switch self {
        case .gold:   return [.clear, Color(red: 1, green: 0.95, blue: 0.6).opacity(0.6), .clear]
        case .silver: return [.clear, Color.white.opacity(0.5), .clear]
        case .bronze: return [.clear, Color(red: 1, green: 0.7, blue: 0.3).opacity(0.4), .clear]
        }
    }
}

struct PlayerCard: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let position: String
    let number: Int
    let overall: Int
    let pace: Int
    let shooting: Int
    let passing: Int
    let defending: Int
    let imageName: String
    let tier: CardTier
}

let allPlayerCards: [PlayerCard] = [
    PlayerCard(name: "Lionel Messi",      country: "Argentina", position: "RW",  number: 10, overall: 93, pace: 85, shooting: 92, passing: 91, defending: 34, imageName: "Messi",        tier: .gold),
    PlayerCard(name: "Cristiano Ronaldo", country: "Portugal",  position: "ST",  number: 7,  overall: 91, pace: 87, shooting: 94, passing: 82, defending: 35, imageName: "Ronaldo",      tier: .gold),
    PlayerCard(name: "Kylian Mbappe",     country: "France",    position: "ST",  number: 10, overall: 92, pace: 97, shooting: 90, passing: 80, defending: 36, imageName: "Mbappe",       tier: .gold),
    PlayerCard(name: "Erling Haaland",    country: "Norway",    position: "ST",  number: 9,  overall: 91, pace: 89, shooting: 93, passing: 65, defending: 45, imageName: "Haaland1",     tier: .silver),
    PlayerCard(name: "Lamine Yamal",      country: "Spain",     position: "RW",  number: 19, overall: 86, pace: 95, shooting: 78, passing: 83, defending: 30, imageName: "LamineYamal",  tier: .silver),
    PlayerCard(name: "Neymar Jr",         country: "Brazil",    position: "LW",  number: 10, overall: 89, pace: 91, shooting: 85, passing: 86, defending: 37, imageName: "NeymarJr",     tier: .gold),
    PlayerCard(name: "Haaland",           country: "Norway",    position: "ST",  number: 23, overall: 91, pace: 89, shooting: 93, passing: 65, defending: 45, imageName: "Haaland2",     tier: .bronze),
    PlayerCard(name: "World Cup Legends", country: "FIFA",      position: "ALL", number: 0,  overall: 99, pace: 99, shooting: 99, passing: 99, defending: 99, imageName: "FIFAWorldCup", tier: .gold),
]

// MARK: - Haptics

private enum PackHaptics {
    static func tear() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func cardFlip() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func rareReveal() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func tick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Card Back View

private struct CardBackView: View {
    let width: CGFloat
    let height: CGFloat

    private let goldDim = Color(red: 1, green: 0.84, blue: 0)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.10, blue: 0.25),
                            Color(red: 0.06, green: 0.05, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            starPattern

            centerLogo

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(goldDim.opacity(0.2), lineWidth: 2)
        }
        .frame(width: width, height: height)
    }

    private var starPattern: some View {
        VStack(spacing: 12) {
            ForEach(0..<8, id: \.self) { _ in
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.04))
                    }
                }
            }
        }
    }

    private var centerLogo: some View {
        VStack(spacing: 12) {
            Image(systemName: "soccerball")
                .font(.system(size: 44))
                .foregroundStyle(goldDim.opacity(0.3))
            Text("ULTIMATE")
                .font(.system(size: 14, weight: .heavy))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.2))
        }
    }
}

// MARK: - Card Front View

private struct CardFrontView: View {
    let card: PlayerCard
    let width: CGFloat
    let height: CGFloat
    var shimmerOffset: CGFloat = 0

    var body: some View {
        ZStack {
            playerImage
            bottomGradient
            tierBadge
            playerInfo
            shimmerOverlay
            borderOverlay
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var playerImage: some View {
        Image(card.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }

    private var bottomGradient: some View {
        VStack(spacing: 0) {
            Spacer()
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.45)
        }
    }

    private var tierBadge: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(card.overall)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(card.tier.color)
                    Text(card.position)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(14)
                .background(
                    .ultraThinMaterial.opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                Spacer()
            }
            Spacer()
        }
        .padding(16)
    }

    private var playerInfo: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name.uppercased())
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                playerSubtitle
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var playerSubtitle: some View {
        HStack(spacing: 8) {
            Text(card.country)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            if card.number > 0 {
                Circle().fill(.white.opacity(0.3)).frame(width: 3, height: 3)
                Text("#\(card.number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(card.tier.color)
            }
        }
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        if card.tier == .gold {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: card.tier.shimmerColors,
                        startPoint: UnitPoint(x: shimmerOffset, y: 0),
                        endPoint: UnitPoint(x: shimmerOffset + 0.4, y: 1)
                    )
                )
                .allowsHitTesting(false)
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [card.tier.color.opacity(0.8), card.tier.color.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }
}

// MARK: - Stat Ring

private struct StatRingView: View {
    let label: String
    let value: Int
    let color: Color
    let animate: Bool
    var delay: Double = 0

    @State private var fillAmount: CGFloat = 0
    @State private var displayedValue: Int = 0

    private let fillDuration: Double = 1.2

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: fillAmount)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                Text("\(displayedValue)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayedValue)
            }
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.5))
        }
        .scaleEffect(animate ? 1 : 0.3)
        .opacity(animate ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: animate)
        .onAppear {
            fillAmount = 0
            displayedValue = 0
            let totalDelay = delay + 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.easeOut(duration: fillDuration)) {
                    fillAmount = CGFloat(value) / 100
                }
                countUp()
            }
        }
    }

    private func countUp() {
        let steps = min(value, 60)
        let interval = fillDuration / Double(max(steps, 1))
        let increment = max(1, value / steps)
        var current = 0
        func tick() {
            current += increment
            if current >= value {
                displayedValue = value
            } else {
                displayedValue = current
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    tick()
                }
            }
        }
        tick()
    }
}

// MARK: - Stats Row

private struct StatsRowView: View {
    let card: PlayerCard
    let animate: Bool

    var body: some View {
        HStack(spacing: 0) {
            StatRingView(label: "PAC", value: card.pace, color: .green, animate: animate, delay: 0.0)
            Spacer()
            StatRingView(label: "SHO", value: card.shooting, color: .orange, animate: animate, delay: 0.08)
            Spacer()
            StatRingView(label: "PAS", value: card.passing, color: .blue, animate: animate, delay: 0.16)
            Spacer()
            StatRingView(label: "DEF", value: card.defending, color: .red, animate: animate, delay: 0.24)
            Spacer()
            StatRingView(label: "OVR", value: card.overall, color: card.tier.color, animate: animate, delay: 0.32)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
    }
}

// MARK: - Sealed Pack View

private struct SealedPackView: View {
    let packW: CGFloat = 310
    let packH: CGFloat = 460
    let appeared: Bool
    let phase: FootballCardPack.PackPhase
    @Binding var tearProgress: CGFloat
    @Binding var shimmerOffset: CGFloat
    var packShake: CGFloat
    var onTearComplete: () -> Void
    var onTearCancel: () -> Void
    var onTearing: (CGFloat) -> Void

    private let goldColor = Color(red: 1, green: 0.84, blue: 0)

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            titleSection
            packBody
            instructionLabel
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("ULTIMATE PACK")
                .font(.system(size: 13, weight: .bold))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.5))

            Text("Football Stars")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [goldColor, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -20)
    }

    private var packBody: some View {
        ZStack {
            packBackground
            packShimmer
            packContent
            tearOverlay
        }
        .rotationEffect(.degrees(Double(packShake)))
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .gesture(tearGesture)
    }

    private var packBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.12, blue: 0.30),
                        Color(red: 0.08, green: 0.06, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: packW, height: packH)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [goldColor.opacity(0.6), goldColor.opacity(0.1), goldColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }

    private var packShimmer: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: UnitPoint(x: shimmerOffset, y: shimmerOffset),
                    endPoint: UnitPoint(x: shimmerOffset + 0.5, y: shimmerOffset + 0.5)
                )
            )
            .frame(width: packW, height: packH)
    }

    private var packContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(goldColor)

            Text("8 PLAYERS")
                .font(.system(size: 18, weight: .heavy))
                .tracking(3)
                .foregroundStyle(.white)

            Text("3 GOLD GUARANTEED")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(goldColor.opacity(0.8))

            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: packW * 0.7, height: 1)
                .padding(.top, 20)

            tearProgressBar
        }
    }

    private var tearProgressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.1))
                .frame(width: packW * 0.7, height: 3)
            Capsule()
                .fill(goldColor.opacity(0.6))
                .frame(width: packW * 0.7 * tearProgress, height: 3)
        }
        .opacity(phase == .tearing ? 1 : 0)
    }

    @ViewBuilder
    private var tearOverlay: some View {
        if phase == .tearing {
            ZStack(alignment: .top) {
                // Player image revealing from top as you swipe
                Image("PackRevealTrophy")
                    .resizable()
                    .scaledToFill()
                    .frame(width: packW, height: packH)
                    .clipped()
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                                .frame(height: packH * tearProgress)
                            Spacer(minLength: 0)
                        }
                    )
                    .overlay(
                        // Soft glow edge at the reveal line
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: max(0, packH * tearProgress - 4))
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 8)
                            Spacer(minLength: 0)
                        }
                    )
            }
            .frame(width: packW, height: packH)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var tearGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { v in
                let pull = -v.translation.height
                if pull > 10 {
                    onTearing(min(1, pull / 250))
                }
            }
            .onEnded { _ in
                if tearProgress > 0.7 {
                    onTearComplete()
                } else {
                    onTearCancel()
                }
            }
    }

    private var instructionLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up")
                .font(.system(size: 14, weight: .bold))
            Text("Swipe up to open")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.4))
        .opacity(phase == .sealed && appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }
}

// MARK: - Card Reveal View

private struct CardRevealView: View {
    let card: PlayerCard
    let nextCard: PlayerCard
    let cardIndex: Int
    let totalCards: Int
    let isFlipped: Bool
    let showStats: Bool
    let shimmerOffset: CGFloat
    let cardW: CGFloat
    let cardH: CGFloat
    let cardRotation: Double
    let showingNextPlayer: Bool
    var onNext: () -> Void
    var onViewAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            Spacer()
            flipCard
            Spacer()
            statsSection
            actionButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayedCard: PlayerCard {
        showingNextPlayer ? nextCard : card
    }

    private var headerRow: some View {
        HStack {
            Text("\(cardIndex + 1) / \(totalCards)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
            Spacer()
            Text(displayedCard.tier.rawValue)
                .font(.system(size: 12, weight: .heavy))
                .tracking(3)
                .foregroundStyle(displayedCard.tier.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(displayedCard.tier.color.opacity(0.15), in: .capsule)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
    }

    private var flipCard: some View {
        // Count half-turns to know if content is mirrored
        let halfTurns = Int(round(cardRotation / 180.0))
        let isMirrored = halfTurns % 2 != 0

        return ZStack {
            if !isFlipped {
                CardBackView(width: cardW, height: cardH)
            } else {
                CardFrontView(
                    card: card,
                    width: cardW,
                    height: cardH,
                    shimmerOffset: shimmerOffset
                )
                // Counter-flip content so text/image always reads correctly
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
            }
        }
        .rotation3DEffect(
            .degrees(cardRotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.35
        )
        .scaleEffect(isFlipped ? 1.02 : 0.95)
        .shadow(
            color: displayedCard.tier.color.opacity(isFlipped ? 0.5 : 0),
            radius: 40, x: 0, y: 24
        )
    }

    @ViewBuilder
    private var statsSection: some View {
        if showStats {
            StatsRowView(card: card, animate: showStats)
                .padding(.horizontal, 28)
                .transition(
                    .asymmetric(
                        insertion: .offset(y: 40).combined(with: .opacity),
                        removal: .opacity
                    )
                )
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isFlipped {
            Group {
                if cardIndex < totalCards - 1 {
                    nextButton
                } else {
                    viewAllButton
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            .transition(
                .asymmetric(
                    insertion: .offset(y: 30).combined(with: .opacity),
                    removal: .opacity
                )
            )
        }
    }

    private var nextButton: some View {
        Pressed3DButton(
            label: "Next Card",
            icon: "arrow.right",
            baseColor: Color.white,
            textColor: .black,
            action: onNext
        )
    }

    private var viewAllButton: some View {
        Pressed3DButton(
            label: "View All Cards",
            icon: "rectangle.stack.fill",
            iconLeading: true,
            baseColor: Color(red: 1, green: 0.84, blue: 0),
            textColor: .black,
            action: onViewAll
        )
    }
}

// MARK: - Glowing Card-Style Button

private struct Pressed3DButton: View {
    let label: String
    var icon: String = "arrow.right"
    var iconLeading: Bool = false
    var baseColor: Color = .white
    var textColor: Color = .black
    var action: () -> Void

    @State private var isPressed = false
    @State private var borderPhase: CGFloat = 0
    @State private var arrowNudge: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.4

    var body: some View {
        buttonContent
            .simultaneousGesture(pressGesture)
            .onAppear { startAnimations() }
    }

    private var buttonContent: some View {
        Button(action: {}) {
            ZStack {
                // Outer glow
                Capsule()
                    .fill(baseColor.opacity(glowPulse * 0.3))
                    .blur(radius: 16)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)

                // Animated gradient border
                Capsule()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                baseColor.opacity(0.8),
                                baseColor.opacity(0.15),
                                baseColor.opacity(0.6),
                                baseColor.opacity(0.1),
                                baseColor.opacity(0.8)
                            ],
                            center: .center,
                            angle: .degrees(Double(borderPhase) * 360)
                        ),
                        lineWidth: 2
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)

                // Glass fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                baseColor.opacity(0.15),
                                baseColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .padding(.horizontal, 1)

                // Label
                buttonLabel
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
    }

    private var buttonLabel: some View {
        HStack(spacing: 10) {
            if iconLeading {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
            }

            Text(label)
                .font(.system(size: 16, weight: .heavy))
                .tracking(1)

            if !iconLeading {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .offset(x: arrowNudge)
            }
        }
        .foregroundStyle(baseColor)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressed else { return }
                isPressed = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .onEnded { v in
                isPressed = false
                if abs(v.translation.width) < 30, abs(v.translation.height) < 30 {
                    action()
                }
            }
    }

    private func startAnimations() {
        // Spinning border
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            borderPhase = 1
        }
        // Arrow nudge
        if !iconLeading {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                arrowNudge = 6
            }
        }
        // Glow pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }
    }
}

// MARK: - Card Browser View

private struct CardBrowserView: View {
    let cards: [PlayerCard]
    @Binding var currentIndex: Int
    let cardW: CGFloat
    let cardH: CGFloat
    let shimmerOffset: CGFloat
    var onNewPack: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            browserHeader
            Spacer()
            cardStack
            Spacer()
            playerDetails
            pageDots
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var browserHeader: some View {
        HStack {
            Button(action: onNewPack) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("New Pack")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Text("YOUR CARDS")
                .font(.system(size: 13, weight: .bold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var cardStack: some View {
        let dragFraction = dragOffset / cardW
        return ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                let continuous = CGFloat(i - currentIndex) + dragFraction
                if abs(continuous) <= 4 {
                    BrowserCardItem(
                        card: card,
                        offset: continuous,
                        isCurrent: abs(continuous) < 0.5,
                        cardW: cardW,
                        cardH: cardH,
                        shimmerOffset: shimmerOffset
                    )
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: currentIndex)
        .gesture(swipeGesture)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                dragOffset = v.translation.width * 0.6
            }
            .onEnded { v in
                let threshold: CGFloat = 50
                if v.predictedEndTranslation.width < -threshold, currentIndex < cards.count - 1 {
                    PackHaptics.tick()
                    currentIndex += 1
                } else if v.predictedEndTranslation.width > threshold, currentIndex > 0 {
                    PackHaptics.tick()
                    currentIndex -= 1
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    dragOffset = 0
                }
            }
    }

    private var playerDetails: some View {
        let card = cards[currentIndex]
        return VStack(spacing: 8) {
            Text(card.name.uppercased())
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .contentTransition(.opacity)
                .id(card.id)

            HStack(spacing: 10) {
                Text(card.country)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Circle().fill(.white.opacity(0.3)).frame(width: 3, height: 3)
                Text(card.position)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(card.tier.color)
                Circle().fill(.white.opacity(0.3)).frame(width: 3, height: 3)
                Text("OVR \(card.overall)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }

    @Namespace private var dotNamespace

    private var pageDots: some View {
        HStack(spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                let isActive = i == currentIndex
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 8, height: 8)

                    if isActive {
                        Capsule()
                            .fill(card.tier.color)
                            .frame(width: 28, height: 8)
                            .shadow(color: card.tier.color.opacity(0.6), radius: 8, x: 0, y: 0)
                            .matchedGeometryEffect(id: "activeDot", in: dotNamespace)
                    }
                }
                .frame(width: isActive ? 28 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: currentIndex)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
}

// MARK: - Browser Card Item

private struct BrowserCardItem: View {
    let card: PlayerCard
    let offset: CGFloat
    let isCurrent: Bool
    let cardW: CGFloat
    let cardH: CGFloat
    let shimmerOffset: CGFloat

    var body: some View {
        let absOff = abs(offset)
        CardFrontView(card: card, width: cardW, height: cardH, shimmerOffset: shimmerOffset)
            .scaleEffect(max(0.82, 1 - absOff * 0.07))
            .offset(x: offset * 40, y: absOff * 14)
            .rotationEffect(.degrees(Double(offset) * 4))
            .opacity(Double(max(0, 1 - absOff * 0.25)))
            .zIndex(-Double(absOff))
            .shadow(color: card.tier.color.opacity(isCurrent ? 0.35 : 0), radius: 22, x: 0, y: 16)
    }
}

// MARK: - Particle

private struct PackParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

private func makePackParticles() -> [PackParticle] {
    var result: [PackParticle] = []
    for i in 0..<20 {
        let xVal = CGFloat(((i * 7 + 3) % 20) - 10) * 18
        let yVal = CGFloat(((i * 13 + 7) % 20) - 10) * 40
        let sizeVal = CGFloat(2 + (i % 3))
        let opacityVal = 0.03 + Double(i % 5) * 0.01
        result.append(PackParticle(id: i, x: xVal, y: yVal, size: sizeVal, opacity: opacityVal))
    }
    return result
}

private let packParticles: [PackParticle] = makePackParticles()

// MARK: - Main View

struct FootballCardPack: View {

    @State private var phase: PackPhase = .sealed
    @State private var tearProgress: CGFloat = 0
    @State private var currentCardIndex = 0
    @State private var isFlipped = false
    @State private var showStats = false
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var packShake: CGFloat = 0
    @State private var appeared = false
    @State private var cardRotation: Double = 0
    @State private var showingNextPlayer = false

    enum PackPhase: Equatable {
        case sealed
        case tearing
        case revealing
        case browsing
    }

    private static let bgColor = Color(red: 0.06, green: 0.06, blue: 0.12)

    var body: some View {
        ZStack {
            Self.bgColor.ignoresSafeArea()
            GeometryReader { geo in
                ZStack {
                    ambientGlow(geo: geo)
                    particlesLayer
                    contentLayer(geo: geo)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15)) {
                appeared = true
            }
            startShimmer()
            startPackShake()
        }
    }

    @ViewBuilder
    private func ambientGlow(geo: GeometryProxy) -> some View {
        if phase == .revealing || phase == .browsing {
            RadialGradient(
                colors: [allPlayerCards[currentCardIndex].tier.color.opacity(0.25), .clear],
                center: .center,
                startRadius: 20,
                endRadius: geo.size.width * 0.8
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: currentCardIndex)
        }
    }

    private var particlesLayer: some View {
        ForEach(packParticles) { p in
            Circle()
                .fill(.white.opacity(p.opacity))
                .frame(width: p.size)
                .offset(x: p.x, y: p.y)
                .blur(radius: 1)
        }
    }

    @ViewBuilder
    private func contentLayer(geo: GeometryProxy) -> some View {
        switch phase {
        case .sealed, .tearing:
            SealedPackView(
                appeared: appeared,
                phase: phase,
                tearProgress: $tearProgress,
                shimmerOffset: $shimmerOffset,
                packShake: packShake,
                onTearComplete: handleTearComplete,
                onTearCancel: handleTearCancel,
                onTearing: handleTearing
            )
        case .revealing:
            let nextIdx = min(currentCardIndex + 1, allPlayerCards.count - 1)
            CardRevealView(
                card: allPlayerCards[currentCardIndex],
                nextCard: allPlayerCards[nextIdx],
                cardIndex: currentCardIndex,
                totalCards: allPlayerCards.count,
                isFlipped: isFlipped,
                showStats: showStats,
                shimmerOffset: shimmerOffset,
                cardW: min(geo.size.width - 48, 340),
                cardH: min(geo.size.width - 48, 340) * 1.5,
                cardRotation: cardRotation,
                showingNextPlayer: showingNextPlayer,
                onNext: nextCard,
                onViewAll: viewAllCards
            )
        case .browsing:
            CardBrowserView(
                cards: allPlayerCards,
                currentIndex: $currentCardIndex,
                cardW: min(geo.size.width - 60, 320),
                cardH: min(geo.size.width - 60, 320) * 1.5,
                shimmerOffset: shimmerOffset,
                onNewPack: resetToSealed
            )
        }
    }

    // MARK: - Actions

    private func handleTearing(_ progress: CGFloat) {
        phase = .tearing
        tearProgress = progress
    }

    private func handleTearComplete() {
        PackHaptics.tear()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            tearProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentCardIndex = 0
            isFlipped = false
            showStats = false
            cardRotation = 0
            showingNextPlayer = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                phase = .revealing
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                flipCurrentCard()
            }
        }
    }

    private func handleTearCancel() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            tearProgress = 0
            phase = .sealed
        }
    }

    private func flipCurrentCard() {
        PackHaptics.cardFlip()

        // Swap to front face at the midpoint of rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isFlipped = true
        }

        // Rotate 180°
        withAnimation(.easeInOut(duration: 0.8)) {
            cardRotation += 180
        }

        if allPlayerCards[currentCardIndex].tier == .gold {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PackHaptics.rareReveal()
            }
        }

        // Show stats after flip settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                showStats = true
            }
        }
    }

    private func nextCard() {
        // Fade out stats
        withAnimation(.easeOut(duration: 0.3)) {
            showStats = false
        }

        PackHaptics.tick()

        // After stats fade, rotate 180° — front → back → new front
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            PackHaptics.cardFlip()

            withAnimation(.easeInOut(duration: 0.8)) {
                cardRotation += 180
            }

            // At ~halfway (card edge-on), swap to next player
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                currentCardIndex += 1
            }

            // After rotation lands, show stats
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                    showStats = true
                }
            }
        }
    }

    private func viewAllCards() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            phase = .browsing
            currentCardIndex = 0
        }
    }

    private func resetToSealed() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            phase = .sealed
            tearProgress = 0
            appeared = true
            startPackShake()
        }
    }

    private func startShimmer() {
        shimmerOffset = -1.5
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.5
        }
    }

    private func startPackShake() {
        withAnimation(
            .easeInOut(duration: 0.08)
                .repeatCount(6, autoreverses: true)
                .delay(2)
        ) {
            packShake = 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            packShake = 0
            if phase == .sealed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    startPackShake()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FootballCardPack()
}
