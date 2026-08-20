//
//  NowPlayingView.swift
//  anim8
//
//  Static recreation of the "Now Playing" movie screen. Built on Apple APIs — the
//  chips/buttons use the native `.glassEffect()` modifier and the bottom bar is a
//  Liquid Glass bar (`GlassEffectContainer` + `.glassEffect()`) laying each tab out
//  as a horizontal icon+title (HStack). Poster artwork and the title logo are
//  placeholders until the supplied image assets are wired in.
//

import SwiftUI
import UIKit

struct NowPlayingView: View {

    enum NavTab: Hashable, CaseIterable {
        case home, moves, alerts, profile

        var title: String {
            switch self {
            case .home:    return "Home"
            case .moves:   return "Moves"
            case .alerts:  return "Alerts"
            case .profile: return "Profile"
            }
        }

        var symbol: String {
            switch self {
            case .home:    return "house"
            case .moves:   return "film.stack"
            case .alerts:  return "bell"
            case .profile: return "person"
            }
        }
    }

    @State private var selectedTab: NavTab = .moves

    var body: some View {
        ZStack(alignment: .bottom) {
            NowPlayingScreen()

            bottomBar
                .padding(.horizontal, 28)
                .padding(.bottom, 6)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Liquid Glass Bottom Bar (one bar; horizontal icon + title per tab)

    private var bottomBar: some View {
        HStack(spacing: 10) {
            ForEach(NavTab.allCases, id: \.self) { tab in
                let isSelected = tab == selectedTab
                Button {
                    guard tab != selectedTab else { return }
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: .regular))
                            .symbolEffect(.bounce, value: isSelected)
                        if isSelected {
                            Text(tab.title)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .glassEffect(.clear, in: .capsule)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
    }
}

// MARK: - Screen Content

private struct Movie: Identifiable {
    let id = UUID()
    let poster: String   // Assets.xcassets image name
    let runtime: String
    let genre: String
}

private let movies: [Movie] = [
    Movie(poster: "Joker",             runtime: "2h 02m", genre: "Drama"),
    Movie(poster: "Wednesday",         runtime: "50m",    genre: "Mystery"),
    Movie(poster: "Cargo",             runtime: "1h 45m", genre: "Thriller"),
    Movie(poster: "MonkeyMan",         runtime: "2h 01m", genre: "Action"),
    Movie(poster: "AvengersEndgame",   runtime: "3h 01m", genre: "Action"),
    Movie(poster: "SASRedNotice",      runtime: "2h 03m", genre: "Action"),
    Movie(poster: "SpiderManNWH",      runtime: "2h 28m", genre: "Action"),
    Movie(poster: "Interstellar",      runtime: "2h 49m", genre: "Sci-Fi"),
    Movie(poster: "F1Movie",           runtime: "2h 35m", genre: "Sport"),
    Movie(poster: "CaptainAmericaBNW", runtime: "1h 58m", genre: "Action"),
    Movie(poster: "LoveInBloom",       runtime: "1h 45m", genre: "Romance"),
]

private struct NowPlayingScreen: View {

    // Stacked-deck tokens
    private let cardWidth: CGFloat = 352      // poster card width
    private let cardHeight: CGFloat = 490     // fixed card height (uniform cards)
    private let visibleCount = 5              // cards visible on screen (front + 4 behind)

    @State private var index = 0
    @State private var dragY: CGFloat = 0     // live downward drag of the front card
    @State private var flying: Movie? = nil   // card currently falling off
    @State private var flyY: CGFloat = 0
    @State private var flyRot: Double = 0
    @State private var didStartDrag = false   // haptic gates
    @State private var didCrossThreshold = false
    private var movie: Movie { movies[index] }

    private let dismissThreshold: CGFloat = 120

    private func tilt(for y: CGFloat) -> Double { min(Double(y) * 0.0125, 5) }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Slot 0 = front; higher = further back. Wraps around for an infinite deck.
    private func slot(for i: Int) -> Int {
        (i - index + movies.count) % movies.count
    }

    /// Cumulative upward offset for a card at `depth`, with the gap shrinking
    /// each step back (e.g. 11, 9, 7, 5…) for a tight stepped stack.
    private func stackOffset(_ depth: Int) -> CGFloat {
        var y: CGFloat = 0
        var step: CGFloat = 18
        for _ in 0..<depth {
            y += step
            step = max(9, step - 3)
        }
        return -y
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1) Top bar: "Coming Soon" outside + a rounded rect holding
            //    "Now Playing" and the "Tomorrow" button.
            topBar
                .padding(.leading, 20)
                .padding(.top, 8)

            // 2) Big rounded card holding the date + poster deck.
            contentCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { background }   // background modifier never affects layout
    }

    // MARK: Top Bar (Coming Soon · [ Now Playing   Tomorrow ])

    private var topBar: some View {
        HStack(spacing: 14) {
            Text("Coming Soon")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))

            HStack(spacing: 0) {
                Text("Now Playing")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer(minLength: 12)
                tomorrowButton
            }
            .padding(.leading, 18)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.black)
            )
            // Two rectangles (behind) filling the bottom-corner notches into the card
            .background(alignment: .bottomLeading) {
                Rectangle().fill(.black).frame(width: 70, height: 70).offset(y: 35)
            }
            .background(alignment: .bottomTrailing) {
                Rectangle().fill(.black).frame(width: 70, height: 96).offset(y: 35)
            }
        }
    }

    private var tomorrowButton: some View {
        Button {
            // no-op (visual only)
        } label: {
            HStack(spacing: 5) {
                Text("Tomorrow")
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .fixedSize()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .fixedSize()
    }

    // MARK: Content Card (date + poster deck)

    private var contentCard: some View {
        VStack(spacing: 0) {
            dateHeadline
                .padding(.horizontal, 22)
                .padding(.top, 52)

            posterCard
                .padding(.horizontal, 14)
                .padding(.top, 46)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.black)
        )
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Background

    private var background: some View {
        GeometryReader { geo in
            Image(movie.poster)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .blur(radius: 20, opaque: true)
                .saturation(1.2)
                // Only the top section shows — fades to black below
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.18),
                            .init(color: .clear, location: 0.42)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        }
        .background(Color.black)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: index)
    }

    // MARK: Date Headline

    private var dateHeadline: some View {
        Text("12 JUN")
            .font(.system(size: 66, weight: .heavy))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(white: 0.55), .white],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: Poster Card

    private var posterCard: some View {
        ZStack(alignment: .top) {
            // The stack (front card follows the finger; the dismissed card is
            // excluded here and rendered as the flying overlay below).
            ForEach(Array(movies.enumerated()), id: \.element.id) { i, m in
                let depth = slot(for: i)               // 0 = front, wraps around
                if depth < visibleCount && m.id != flying?.id {
                    cardView(m, depth: depth)
                        .scaleEffect(1 - 0.07 * CGFloat(depth), anchor: .top)
                        .rotationEffect(depth == 0 ? .degrees(tilt(for: dragY)) : .zero,
                                        anchor: .bottom)
                        .offset(y: stackOffset(depth) + (depth == 0 ? dragY : 0))
                        .zIndex(Double(visibleCount - depth))
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                }
            }

            // Dismissed card falling off — independent of the stack, so the
            // second card rises to the front at the same time.
            if let f = flying {
                cardView(f, depth: 0)
                    .rotationEffect(.degrees(flyRot), anchor: .bottom)
                    .offset(y: flyY)
                    .zIndex(100)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.45), value: index)
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { v in
                    guard flying == nil else { return }
                    let y = max(0, v.translation.height)
                    if !didStartDrag, y > 2 {                 // touch-down / drag begins
                        didStartDrag = true
                        impact(.light)
                    }
                    if !didCrossThreshold, y > dismissThreshold {   // armed to dismiss
                        didCrossThreshold = true
                        impact(.medium)
                    } else if didCrossThreshold, y <= dismissThreshold {
                        didCrossThreshold = false               // re-arm if dragged back up
                    }
                    dragY = y
                }
                .onEnded { v in
                    guard flying == nil else { return }
                    didStartDrag = false
                    didCrossThreshold = false
                    if v.predictedEndTranslation.height > dismissThreshold {
                        impact(.heavy)                          // commit
                        advance(fromDrag: dragY)
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { dragY = 0 }
                    }
                }
        )
        .task {
            // Auto-advance: each card is shown for ~2.5s, then drops away.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                if flying == nil { advance(fromDrag: 0) }
            }
        }
    }

    /// Drop the front card off-screen while the next rises to the front.
    private func advance(fromDrag startY: CGFloat) {
        flying = movies[index]
        flyY = startY
        flyRot = tilt(for: startY)
        dragY = 0
        withAnimation(.easeInOut(duration: 0.55)) {
            index = (index + 1) % movies.count
        }
        withAnimation(.easeIn(duration: 0.85)) {
            flyY = 1100
            flyRot = 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.87) {
            flying = nil; flyY = 0; flyRot = 0
        }
    }

    private func cardView(_ movie: Movie, depth: Int) -> some View {
        let posterShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return Image(movie.poster)
            .resizable()
            .scaledToFill()
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(posterShape)
            .overlay {
                // Cards behind are dimmed by depth
                posterShape.fill(Color.black.opacity(0.16 * Double(depth)))
            }
            .overlay(alignment: .topLeading) {
                if depth == 0 {
                    metaChips
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                }
            }
            // Image-colored shadow: a blurred copy of the poster behind the card
            .background {
                if depth == 0 {
                    Image(movie.poster)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(posterShape)
                        .blur(radius: 34)
                        .opacity(0.65)
                        .offset(y: 22)
                        .scaleEffect(0.96)
                }
            }
    }

    private var metaChips: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                pill(movie.runtime)
                pill(movie.genre)
            }
            Spacer()
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            // Static translucent capsule — stays consistent while the card moves.
            // (A live glassEffect re-samples the background and appears to grow.)
            .background(Color.black.opacity(0.45), in: .capsule)
    }
}

// MARK: - Preview

#Preview {
    NowPlayingView()
}
