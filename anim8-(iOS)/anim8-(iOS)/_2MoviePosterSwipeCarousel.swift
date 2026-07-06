//
//  MoviePosterSwipeCarousel.swift
//  legendary-Animo
//
//  Swipe-to-browse movie poster carousel — "flipping through cinema posters."
//  Velocity-aware paging, fanned card-stack with depth, cross-fading immersive
//  backdrop, and selection haptics. Self-contained (no image assets required).
//

import SwiftUI
import UIKit

// MARK: - Model

private struct Movie: Identifiable {
    let id = UUID()
    let title: String
    let genre: String
    let year: String
    let runtime: String
    let rating: String
    let imageName: String
}

private let movies: [Movie] = [
    Movie(title: "Avengers: Endgame", genre: "Action",   year: "2019", runtime: "3h 01m", rating: "8.4", imageName: "AvengersEndgame"),
    Movie(title: "Interstellar",      genre: "Sci-Fi",   year: "2014", runtime: "2h 49m", rating: "8.6", imageName: "Interstellar"),
    Movie(title: "Joker",             genre: "Crime",    year: "2019", runtime: "2h 02m", rating: "8.4", imageName: "Joker"),
    Movie(title: "Spider-Man: NWH",   genre: "Action",   year: "2021", runtime: "2h 28m", rating: "8.2", imageName: "SpiderManNWH"),
    Movie(title: "Monkey Man",        genre: "Thriller", year: "2024", runtime: "2h 01m", rating: "7.1", imageName: "MonkeyMan"),
    Movie(title: "F1",                genre: "Sports",   year: "2025", runtime: "2h 10m", rating: "7.5", imageName: "F1Movie"),
    Movie(title: "Wednesday",         genre: "Mystery",  year: "2022", runtime: "1h 00m", rating: "8.1", imageName: "Wednesday"),
    Movie(title: "Cargo",             genre: "Drama",    year: "2017", runtime: "1h 45m", rating: "6.9", imageName: "Cargo"),
    Movie(title: "Love In Bloom",     genre: "Romance",  year: "2024", runtime: "1h 52m", rating: "7.2", imageName: "LoveInBloom"),
    Movie(title: "SAS: Red Notice",   genre: "Action",   year: "2021", runtime: "2h 01m", rating: "5.7", imageName: "SASRedNotice"),
    Movie(title: "Captain America",   genre: "Action",   year: "2025", runtime: "1h 59m", rating: "6.5", imageName: "CaptainAmericaBNW"),
]

// MARK: - Main View

struct MoviePosterSwipeCarousel: View {

    // Tokens
    private let cardW: CGFloat = 286
    private let cardH: CGFloat = 430
    private let xStep: CGFloat = 232    // horizontal gap between adjacent posters
    private let dragResistance: CGFloat = 0.55

    // State
    @State private var selectedIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var appeared = false

    private var current: Movie { movies[selectedIndex] }

    var body: some View {
        ZStack {
            backdrop
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)

                Spacer(minLength: 0)
                carousel
                Spacer(minLength: 0)

                details
                pageDots.padding(.top, 18)
                watchButton.padding(.top, 22)
            }
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.05)) {
                appeared = true
            }
        }
    }

    // MARK: Backdrop — blurred poster image of the selected card (always in sync)

    private var backdrop: some View {
        GeometryReader { geo in
            ZStack {
                Color(white: 0.05)
                ForEach(movies.indices, id: \.self) { i in
                    Image(movies[i].imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(i == selectedIndex ? 1 : 0)
                        .animation(.easeInOut(duration: 0.55), value: selectedIndex)
                }
                .blur(radius: 80, opaque: true)
                .saturation(1.3)

                // Legibility scrim — darker top & bottom
                LinearGradient(colors: [.black.opacity(0.55), .clear, .black.opacity(0.70)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("NOW SHOWING")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Pick a film")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "ticket.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white.opacity(0.12)))
                .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1))
        }
    }

    // MARK: Carousel

    private var carousel: some View {
        ZStack {
            ForEach(movies.indices, id: \.self) { i in
                posterCard(movies[i])
                    .frame(width: cardW, height: cardH)
                    .scaleEffect(scale(for: i))
                    .rotationEffect(.degrees(rotation(for: i)))
                    .offset(x: CGFloat(i - selectedIndex) * xStep + dragOffset,
                            y: yOffset(for: i))
                    .opacity(opacity(for: i))
                    .blur(radius: blur(for: i))
                    .zIndex(-abs(effectiveDistance(for: i)))
            }
        }
        .frame(height: cardH + 40)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { v in dragOffset = v.translation.width * dragResistance }
                .onEnded { v in
                    let threshold: CGFloat = 50
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                        if v.predictedEndTranslation.width < -threshold, selectedIndex < movies.count - 1 {
                            selectedIndex += 1; selectionHaptic()
                        } else if v.predictedEndTranslation.width > threshold, selectedIndex > 0 {
                            selectedIndex -= 1; selectionHaptic()
                        }
                        dragOffset = 0
                    }
                }
        )
    }

    private func posterCard(_ movie: Movie) -> some View {
        ZStack {
            // Poster image
            Image(movie.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: cardW, height: cardH)
                .clipped()

            // Gloss highlight
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.18), .clear],
                                     startPoint: .topLeading, endPoint: .center))
                .blendMode(.softLight)

            // Bottom text scrim + meta
            VStack {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.55)],
                               startPoint: .center, endPoint: .bottom)
                    .frame(height: 180)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(movie.rating)
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.35))

                            Text(movie.title)
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("\(movie.genre)  ·  \(movie.year)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        .padding(20)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 18)
    }

    // MARK: Details (below carousel — driven by selection)

    private var details: some View {
        VStack(spacing: 10) {
            Text(current.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.opacity)
                .id(current.id)

            HStack(spacing: 10) {
                metaChip(current.genre)
                metaDot
                metaChip(current.year)
                metaDot
                metaChip(current.runtime)
            }
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .contentTransition(.opacity)
            .id(text + current.title)
    }

    private var metaDot: some View {
        Circle().fill(.white.opacity(0.35)).frame(width: 3, height: 3)
    }

    // MARK: Page dots

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(movies.indices, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(i == selectedIndex ? 0.95 : 0.3))
                    .frame(width: i == selectedIndex ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedIndex)
    }

    // MARK: Watch CTA

    private var watchButton: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.fill").font(.system(size: 15, weight: .bold))
            Text("Watch Trailer").font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(Color(white: 0.08))
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Capsule().fill(.white))
        .padding(.horizontal, 40)
        .pressable(scale: 0.97)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: Layout math — fluid "flipping" transform per card

    /// Signed distance from the selected card, blended with the live drag so
    /// neighbours grow/shrink continuously while the finger moves.
    private func effectiveDistance(for i: Int) -> CGFloat {
        CGFloat(i - selectedIndex) - (dragOffset / cardW)
    }

    private func scale(for i: Int) -> CGFloat {
        max(0.82, 1.0 - 0.12 * abs(effectiveDistance(for: i)))
    }

    private func rotation(for i: Int) -> Double {
        let d = effectiveDistance(for: i)
        return Double(max(-2, min(2, d)) * 7)   // ±14° cap
    }

    private func yOffset(for i: Int) -> CGFloat {
        abs(effectiveDistance(for: i)) * 18 - (i == selectedIndex ? 8 : 0)
    }

    private func opacity(for i: Int) -> Double {
        Double(max(0.0, 1.0 - 0.28 * abs(effectiveDistance(for: i))))
    }

    private func blur(for i: Int) -> CGFloat {
        min(4, abs(effectiveDistance(for: i)) * 2)
    }

    // MARK: Haptics (no project HapticFeedback.swift — inline UIKit)

    private func selectionHaptic() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
}

// MARK: - Supporting Shapes

/// Press feedback — shrinks under the finger, light haptic on the down edge,
/// lift-inside-to-fire. Gesture-driven so it won't block parent gestures.
private struct PressableScale: ViewModifier {
    var pressedScale: CGFloat = 0.96
    let action: () -> Void
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .onEnded { v in
                        isPressed = false
                        if abs(v.translation.width) < 20, abs(v.translation.height) < 20 { action() }
                    }
            )
    }
}

private extension View {
    func pressable(scale: CGFloat = 0.96, action: @escaping () -> Void = {}) -> some View {
        modifier(PressableScale(pressedScale: scale, action: action))
    }
}

// MARK: - Preview

#Preview {
    MoviePosterSwipeCarousel()
}
