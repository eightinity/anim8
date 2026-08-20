import SwiftUI
import UIKit

// MARK: - Model

struct Album: Identifiable {
    var id: String { image }
    let image: String
    let title: String
    let artist: String
}

// MARK: - Sample Data

private let sampleAlbums: [Album] = [
    Album(image: "Mercury",           title: "Mercury – Acts 1 & 2",             artist: "Imagine Dragons"),
    Album(image: "SonnyBoy",          title: "Sonny Boy",                         artist: "Yoshiaki Nishi"),
    Album(image: "MercyMe",           title: "Always Only Jesus",                 artist: "MercyMe"),
    Album(image: "Mamamoo47",         title: "4/7",                               artist: "MAMAMOO"),
    Album(image: "IDle",              title: "(G)I-DLE",                          artist: "(G)I-DLE"),
    Album(image: "YanBlock",          title: "4/4/x4",                            artist: "Yan Block & Panda Black"),
    Album(image: "PinkTape",          title: "Pink Tape",                         artist: "Lil Uzi Vert"),
    Album(image: "JayZ444",           title: "4:44",                              artist: "JAY-Z"),
    Album(image: "IVESecret",         title: "IVE SECRET",                        artist: "IVE"),
    Album(image: "Day6Gravity",       title: "The Book of Us: Gravity",           artist: "DAY6"),
    Album(image: "RedVelvetBirthday", title: "Birthday",                          artist: "Red Velvet"),
    Album(image: "ViceVersa",         title: "Vice Versa",                        artist: "Rauw Alejandro"),
    Album(image: "TeenRomance",       title: "Teen Romance",                      artist: "Gus Dapperton"),
    Album(image: "QueenMiracle",      title: "The Miracle",                       artist: "Queen"),
    Album(image: "BTSMapSoul7",       title: "Map of the Soul: 7",                artist: "BTS"),
    Album(image: "Ayliva",            title: "Weisses Herz",                      artist: "Ayliva"),
    Album(image: "Beyonce4",          title: "4",                                 artist: "Beyoncé"),
    Album(image: "TXTStar",           title: "The Dream Chapter: Star",           artist: "TOMORROW X TOGETHER"),
    Album(image: "LPLostOnYou",       title: "Lost On You",                       artist: "LP"),
    Album(image: "SpiderVerse",       title: "Spider-Man: Into the Spider-Verse", artist: "Post Malone & Swae Lee"),
    Album(image: "AmericanTeen",      title: "American Teen",                     artist: "Khalid"),
    Album(image: "WickedSoundtrack",  title: "Wicked: The Soundtrack",            artist: "Stephen Schwartz"),
    Album(image: "AgustDD2",          title: "D-2",                               artist: "Agust D"),
    Album(image: "IULilac",           title: "Lilac",                             artist: "IU"),
    Album(image: "SailorSong",        title: "Sailor Song",                       artist: "Grentperez"),
    Album(image: "StrangerThings4",   title: "Stranger Things: Season 4",         artist: "Various Artists"),
    Album(image: "TeddySwims",        title: "I've Tried Everything But Therapy", artist: "Teddy Swims"),
    Album(image: "HurryUpTomorrow",   title: "Hurry Up Tomorrow",                 artist: "The Weeknd"),
    Album(image: "JusticeJB",         title: "Justice",                           artist: "Justin Bieber"),
    Album(image: "BrandNewEyes",      title: "Brand New Eyes",                    artist: "Paramore"),
    Album(image: "DumanOyleDertli",   title: "Öyle Dertli",                       artist: "Duman"),
    Album(image: "Kauai",             title: "Kauai",                             artist: "Childish Gambino"),
    Album(image: "Starboy",           title: "Starboy",                           artist: "The Weeknd"),
    Album(image: "EnemyArcane",       title: "Enemy",                             artist: "Imagine Dragons & JID"),
]

// MARK: - Haptics

private enum CarouselHaptics {
    private static let tickGenerator     = UISelectionFeedbackGenerator()
    private static let boundaryGenerator = UIImpactFeedbackGenerator(style: .rigid)

    static func prepare() {
        tickGenerator.prepare()
        boundaryGenerator.prepare()
    }

    static func tick() {
        tickGenerator.selectionChanged()
        tickGenerator.prepare()
    }

    static func boundary() {
        boundaryGenerator.impactOccurred(intensity: 0.55)
        boundaryGenerator.prepare()
    }
}

// MARK: - Native scroll physics

/// Invisible `UIScrollView` that drives offset with real UIKit deceleration — no snap springs.
private struct NativeScrollDriver: UIViewRepresentable {
    @Binding var scrollOffset: CGFloat
    let stackSpacing: CGFloat
    let maxScrollOffset: CGFloat
    @Binding var lastHapticIndex: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.decelerationRate = .normal
        scrollView.backgroundColor = .clear
        scrollView.isOpaque = false

        let content = UIView()
        content.backgroundColor = .clear
        scrollView.addSubview(content)

        context.coordinator.scrollView = scrollView
        context.coordinator.contentView = content
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self

        let scrollable = max(maxScrollOffset * stackSpacing, 1)
        let contentHeight = scrollable + scrollView.bounds.height
        context.coordinator.contentView?.frame = CGRect(
            x: 0, y: 0,
            width: max(scrollView.bounds.width, 1),
            height: contentHeight
        )
        scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: contentHeight)

        guard !context.coordinator.isTracking, !context.coordinator.isDecelerating else { return }

        let targetY = scrollOffset * stackSpacing
        if abs(scrollView.contentOffset.y - targetY) > 0.5 {
            scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: NativeScrollDriver
        weak var scrollView: UIScrollView?
        weak var contentView: UIView?
        var isTracking = false
        var isDecelerating = false
        var boundaryFired = false

        init(parent: NativeScrollDriver) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.y / parent.stackSpacing
            parent.scrollOffset = offset

            let crossed = Int(floor(offset + 0.5))
            if crossed != parent.lastHapticIndex {
                CarouselHaptics.tick()
                parent.lastHapticIndex = crossed
            }

            let pastTop = scrollView.contentOffset.y < -4
            let pastBottom = scrollView.contentOffset.y > parent.maxScrollOffset * parent.stackSpacing + 4
            if (pastTop || pastBottom), !boundaryFired {
                CarouselHaptics.boundary()
                boundaryFired = true
            }
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isTracking = true
            boundaryFired = false
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            isTracking = false
            if !decelerate { isDecelerating = false }
        }

        func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
            isDecelerating = true
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDecelerating = false
        }
    }
}

// MARK: - Carousel

struct StackedAlbumCarousel: View {
    var albums: [Album] = sampleAlbums

    @State private var scrollOffset: CGFloat = 0
    @State private var lastHapticIndex = 0

    private let stackSpacing: CGFloat = 88
    private let stackItemHeight: CGFloat = 328
    private let topPad: CGFloat = 52
    private let renderWindow: CGFloat = 11

    private var maxScrollOffset: CGFloat {
        CGFloat(max(albums.count - 1, 0))
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth  = geo.size.width
            let cardHeight = geo.size.height
            let centerOff  = topPad + stackItemHeight / 2 - geo.size.height / 2

            ZStack {
                carouselBackground

                ZStack {
                    ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                        let scrollProgress = CGFloat(index) - scrollOffset
                        let yOff           = centerOff + scrollProgress * stackSpacing
                        let scale          = Album3DLayout.scale(scrollProgress: scrollProgress)
                        let opacity        = Album3DLayout.opacity(scrollProgress: scrollProgress)
                        let tiltX          = Album3DLayout.tiltX(scrollProgress: scrollProgress)

                        if abs(scrollProgress) <= renderWindow {
                            Album3DCarouselCard(album: album, tiltX: tiltX)
                                .frame(width: cardWidth, height: cardHeight)
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .offset(y: yOff)
                                .zIndex(Double(albums.count) - abs(scrollProgress))
                        }
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .allowsHitTesting(false)

                NativeScrollDriver(
                    scrollOffset: $scrollOffset,
                    stackSpacing: stackSpacing,
                    maxScrollOffset: maxScrollOffset,
                    lastHapticIndex: $lastHapticIndex
                )
                .frame(width: cardWidth, height: cardHeight)
            }
        }
        .ignoresSafeArea()
        .background(Color.clear)
        .onAppear {
            CarouselHaptics.prepare()
            lastHapticIndex = 0
        }
    }

    private var carouselBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.48, blue: 0.28),
                Color(red: 0.25, green: 0.15, blue: 0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card

private struct Album3DCarouselCard: View {
    let album: Album
    var tiltX: Float

    var body: some View {
        Album3DView(
            imageName: album.image,
            title: album.title,
            artist: album.artist,
            tiltX: tiltX,
            embedded: true
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .background(Color.clear)
    }
}

#Preview {
    StackedAlbumCarousel()
}
