import SwiftUI

/// Photo viewer with two states, toggled by tapping the image:
/// - chrome hidden: just a page counter, image, title and date
/// - chrome visible: status bar, back/grid buttons and a thumbnail strip
struct GalleryDetailView: View {
    let items: [GalleryItem]
    var onBack: (() -> Void)? = nil

    /// Where the pager currently sits, in pages, and the single value the whole screen is drawn from:
    /// the card's offset, the caption riding with it, every thumbnail's size and outline. Fractional  
    /// between pages, so whatever moves it — a card swipe, a strip drag, a tap — animates all of it
    /// identically. Nothing here has an animation of its own; they all just follow this number.
    @State private var pageProgress: Double
    /// Page position when the current gesture began, held for its duration so the drag is measured
    /// against a fixed origin instead of accumulating its own output.
    @State private var dragAnchor: Double?
    @State private var isChromeVisible: Bool

    init(items: [GalleryItem], startIndex: Int = 0, startChromeVisible: Bool = true, onBack: (() -> Void)? = nil) {
        self.items = items
        self.onBack = onBack
        _pageProgress = State(initialValue: Double(startIndex))
        _isChromeVisible = State(initialValue: startChromeVisible)
    }

    /// Page turns. A hair of overshoot before it settles is what gives a swipe weight; fully damped,
    /// a page just glides to a stop and reads as sluggish rather than as smooth.
    private static let pageMotion = Animation.spring(response: 0.42, dampingFraction: 0.72)
    /// How far the header has to travel to clear the button, the top safe area and a little margin.
    private static let headerLift: CGFloat = 110
    /// Entering and leaving the immersive state. Slower and flatter than a page turn — the artwork is
    /// growing across most of the screen, and at the page spring's speed that reads as a pop. Paced
    /// to the thumbnail strip's own travel so the two settle together.
    private static let chromeMotion = Animation.spring(duration: 0.6, bounce: 0.08)

    private var total: Int { items.count }

    private var selection: Int {
        min(max(Int(pageProgress.rounded()), 0), max(total - 1, 0))
    }

    var body: some View {
        ZStack {
            GalleryColor.backgroundGradient.ignoresSafeArea()

            // The pager is hand-rolled rather than a paging ScrollView. A ScrollView's paging behaviour
            // rounds *every* scroll to a whole page, including programmatic ones, so anything driving it
            // from outside — the thumbnail strip — could only ever make it jump from image to image.
            // Owning the offset outright is what lets one continuous value move everything at once.
            GeometryReader { proxy in
                let width = proxy.size.width

                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        // Signed distance from the viewer, in pages. Fractional mid-swipe, and the
                        // only thing the caption is drawn from — so it follows the drag frame for
                        // frame and then rides the release spring's settle, without owning an
                        // animation of its own. Same arrangement as the thumbnail strip.
                        let distance = Double(index) - pageProgress
                        GalleryPage(
                            item: item,
                            chromeVisible: isChromeVisible,
                            // Past a full page away there is no part of it on screen, so it doesn't
                            // need drawing — see `isNearby`.
                            isNearby: abs(distance) < 1.5,
                            // Exactly undoes the pager's translation for this page, which pins the
                            // caption to the centre of the screen while the artwork slides past it.
                            captionShift: CGFloat(-distance) * width,
                            captionFocus: CGFloat(max(0, 1 - abs(distance)))
                        ) {
                            withAnimation(Self.chromeMotion) { isChromeVisible.toggle() }
                        }
                        .frame(width: width, height: proxy.size.height)
                    }
                }
                .offset(x: -CGFloat(pageProgress) * width)
                .contentShape(Rectangle())
                .gesture(cardDrag(width: width))
            }

            VStack {
                Text("\(selection + 1)/\(total)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GalleryColor.muted)
                    .padding(.top, 8)
                    .opacity(isChromeVisible ? 0 : 1)
                    .animation(counterMotion, value: isChromeVisible)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack {
                // Mounted in both states and parked above the top edge, for the same reason as the
                // thumbnail strip: a view removed from the hierarchy has nothing left to slide, and
                // one half of the chrome sliding while the other half fades reads as two unrelated
                // animations rather than as one screen changing state.
                HStack {
                    GalleryChromeButton(systemImage: "chevron.left") {
                        onBack?()
                    }
                    Spacer()
                    GalleryChromeButton(systemImage: "square.grid.2x2") {}
                }
                .padding(.horizontal, 20)
                .offset(y: isChromeVisible ? 0 : -Self.headerLift)
                .animation(Self.chromeMotion, value: isChromeVisible)
                .allowsHitTesting(isChromeVisible)

                Spacer()

                // Every interaction — swiping the card, dragging the strip, tapping a thumbnail —
                // ends up moving the pager, and the pager's offset is what the strip reads back.
                // One source of truth, so the two can never disagree mid-flight.
                //
                // Always mounted, never conditionally inserted: the thumbnails leave by sliding off
                // the bottom one after another, and a view that has been removed from the hierarchy
                // has nothing left to slide. It's parked below the screen instead.
                GalleryThumbnailStrip(
                    items: items,
                    progress: pageProgress,
                    isPresented: isChromeVisible,
                    onScrub: { page in
                        pageProgress = min(max(page, 0), Double(max(total - 1, 0)))
                    },
                    onSettle: { index in
                        withAnimation(Self.pageMotion) { pageProgress = Double(index) }
                    }
                )
                .padding(.bottom, 12)
            }
        }
        .statusBar(hidden: !isChromeVisible)
        // A page landing is a discrete step through a list, so it gets the same feedback a picker
        // gives. Keyed to `selection` rather than to any one gesture, so a card swipe, a strip fling
        // and a thumbnail tap all report identically — including mid-fling, one tick per page passed.
        .sensoryFeedback(.selection, trigger: selection)
        // Changing state is a commit rather than a step, so it gets weight instead of a tick.
        .sensoryFeedback(.impact(weight: .medium), trigger: isChromeVisible)
    }

    /// The counter waits for the chrome to be most of the way out before fading in, and leaves at
    /// once on the way back, so the two are never on screen together.
    private var counterMotion: Animation {
        .easeOut(duration: 0.22).delay(isChromeVisible ? 0 : 0.2)
    }

    /// Swiping the artwork. Assigns `pageProgress` unanimated so the card tracks the finger exactly,
    /// then springs to a whole page on release — one page per swipe, as a paging scroll view behaves,
    /// so a hard flick doesn't skip three images.
    private func cardDrag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard width > 0 else { return }
                let anchor = dragAnchor ?? pageProgress
                if dragAnchor == nil { dragAnchor = anchor }
                pageProgress = resisted(anchor - Double(value.translation.width / width))
            }
            .onEnded { value in
                guard width > 0 else { return }
                let anchor = dragAnchor ?? pageProgress
                dragAnchor = nil
                let predicted = anchor - Double(value.predictedEndTranslation.width / width)
                let start = anchor.rounded()
                let target = min(max(predicted.rounded(), start - 1), start + 1)
                withAnimation(Self.pageMotion) {
                    pageProgress = min(max(target, 0), Double(max(total - 1, 0)))
                }
            }
    }

    /// Past either end there is nothing to show, so the card only follows the finger part of the way —
    /// the same give a scroll view has when you pull against its edge.
    private func resisted(_ page: Double) -> Double {
        let last = Double(max(total - 1, 0))
        if page < 0 { return page * 0.3 }
        if page > last { return last + (page - last) * 0.3 }
        return page
    }
}

private struct GalleryPage: View {
    let item: GalleryItem
    /// Drives the layout, not just what's on screen: hiding the chrome frees the margins the buttons
    /// and the thumbnail strip were holding, and the artwork takes them.
    let chromeVisible: Bool
    /// Whether this page is close enough to the viewer to be worth drawing. The feathered edge is a
    /// blur, and a blur is an offscreen render pass — twelve of them alive at once is what costs the
    /// pager its frame rate on a device, and eleven are for pages more than a screen width away. The
    /// placeholder keeps the same aspect ratio, so the layout is identical either way and nothing
    /// shifts when a page swaps in.
    let isNearby: Bool
    /// How far to slide the caption inside its own page to cancel the pager's translation. The
    /// caption belongs to the screen rather than to the artwork: it holds the centre while the images
    /// travel past, and changes by resolving out of a blur instead of by sliding away.
    let captionShift: CGFloat
    /// 1 when this page is centred, falling linearly to 0 a full page away.
    let captionFocus: CGFloat
    let onTapImage: () -> Void

    private static let cardShape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    /// Side margin around the artwork. Immersive, it pulls back to almost nothing so the artwork runs
    /// nearly the full width of the screen — that growth is the whole point of the state.
    private var sideInset: CGFloat { chromeVisible ? 36 : 8 }
    /// Room kept below the caption. With the chrome up this is the thumbnail strip's; with it down
    /// there is nothing to clear, so the caption settles toward the bottom of the screen.
    private var bottomInset: CGFloat { chromeVisible ? 108 : 26 }

    /// Where the dissolve is half done, measured in from the card's edge.
    private static let feather: CGFloat = 12
    /// Softness of the dissolve. Deliberately well under `feather`: the blur is a gaussian, so it
    /// needs roughly 2.5× its radius to die out completely, and any alpha still left when the ramp
    /// reaches the card's bounds gets cut off square — which is the faint hard line along the edge
    /// of a dark artwork. At this ratio the ramp is already at zero a little inside the boundary,
    /// so there is nothing left to cut.
    private static let featherSoftness: CGFloat = 4.5

    /// How far out of focus a caption goes at a full page away. Enough that two of them overlapping
    /// mid-swipe read as one indistinct smear rather than as two legible titles printed over
    /// each other.
    private static let captionBlur: CGFloat = 11

    /// Built off a `Color.clear` with a `.fit` aspect ratio rather than the image directly — a `.fill`
    /// image asked for its own size returns the size that fills, which is unbounded.
    private var artwork: some View {
        Color.clear
            .aspectRatio(0.8, contentMode: .fit)
            .overlay(
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .clipShape(Self.cardShape)
    }

    /// The soft edge. The card's own alpha ramps out to nothing over the last few points, so the
    /// artwork dissolves into the background instead of stopping against it — no border, no shadow,
    /// nothing drawn *around* the card at all. Masking rather than painting white over the edge is
    /// what keeps it honest on the warm gray backdrop: the background shows through as itself.
    ///
    /// The ramp is a rounded rectangle pulled in by `feather` and then blurred, which is what feathers
    /// the corners on the same curve as the straight edges — a gradient per side would leave the
    /// corners hard.
    private var edgeFade: some View {
        Self.cardShape
            .fill(.white)
            .padding(Self.feather)
            .blur(radius: Self.featherSoftness)
            // The reference is softest along the bottom, where the artwork lifts off the page, and
            // holds together best at the top under the chrome. This tilts the otherwise even fade.
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.90),
                        .init(color: .white.opacity(0.7), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }

    private var caption: some View {
        VStack(spacing: 4) {
            Text(item.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(GalleryColor.ink)
            Text("Added \(item.dateAdded)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(GalleryColor.muted)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        // Fixed to one line so a long title can't change the caption's height as it blurs past —
        // the block below it would step up and down mid-swipe.
        .lineLimit(1)
    }

    var body: some View {
        VStack(spacing: 0) {
            // A capped spacer above and an uncapped one below: the artwork settles just under the
            // chrome while the caption floats down toward the thumbnail strip, as in the design.
            Spacer(minLength: 0).frame(maxHeight: 24)

            Group {
                if isNearby {
                    artwork.mask { edgeFade }
                } else {
                    Color.clear.aspectRatio(0.8, contentMode: .fit)
                }
            }
                .padding(.horizontal, sideInset)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTapImage)

            Spacer(minLength: 24)

            // Out of focus and faded while the page is in flight, sharpening as it arrives. Both are
            // pure functions of `captionFocus`, so there is no animation here to fall out of step
            // with the artwork — the caption resolves on precisely the clock the image settles on,
            // including mid-drag and through the release spring's overshoot.
            //
            // Held off screen entirely beyond a page away rather than merely faded out: a blur is an
            // offscreen render pass, and twelve of them for captions nobody can see costs as much as
            // twelve blurred artworks did.
            Group {
                if captionFocus > 0 {
                    caption
                        .blur(radius: Self.captionBlur * (1 - captionFocus))
                        .opacity(Double(captionFocus))
                        .offset(x: captionShift)
                } else {
                    caption.hidden()
                }
            }

            // Immersive, the caption is the last thing on the screen and sits right down on the safe
            // area; with the chrome up it needs to keep its distance from the thumbnail strip.
            Spacer(minLength: 0).frame(maxHeight: chromeVisible ? 28 : 0)
        }
        .frame(maxWidth: .infinity)
        // The top inset holds in both states, so the artwork grows downward from a fixed line rather
        // than drifting up under the counter.
        .padding(.top, 64)
        .padding(.bottom, bottomInset)
    }
}

private struct GalleryChromeButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(GalleryColor.icon)
                .frame(width: 40, height: 40)
                // Liquid Glass rather than a painted white disc: the artwork and the background
                // gradient running underneath refract through it instead of being covered by an
                // opaque chip. The light backdrop is what makes this worth doing — glass has almost
                // nothing to refract on a dark one.
                //
                // No drop shadow. Glass separates itself from a light background on its own, and a
                // shadow beneath it reads as the flat disc this is replacing.
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(GalleryChromeButtonStyle())
    }
}

/// Carries the press haptic and nothing else. The glass supplies its own press response through
/// `.interactive()`, so there is deliberately no `scaleEffect` here — two press animations on one
/// control fight each other. Written as a `ButtonStyle` rather than as a raw `DragGesture` so the
/// control keeps its button semantics for VoiceOver and Switch Control; `configuration.isPressed`
/// already flips on the touch-down edge, which is the only thing a gesture would have bought.
private struct GalleryChromeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Down edge only — a tap should feel like one contact, not like a press and a release.
            .sensoryFeedback(trigger: configuration.isPressed) { _, pressed in
                pressed ? .impact(weight: .light) : nil
            }
    }
}

private struct GalleryThumbnailStrip: View {
    let items: [GalleryItem]
    /// The pager's position in pages, fractional mid-swipe.
    let progress: Double
    /// Whether the strip belongs on screen. False parks it below the bottom edge.
    let isPresented: Bool
    /// Fractional page the finger is currently over, emitted every frame of a drag.
    let onScrub: (Double) -> Void
    /// Whole page to settle on, from a lifted finger or a tap.
    let onSettle: (Int) -> Void

    /// The three tiers of the row: the focused image, its two immediate neighbours a step down from
    /// it, and everything beyond them at the smallest size. `matInset` is the white mat that appears
    /// around the focused one only.
    private let restSize: CGFloat = 34
    private let mediumSize: CGFloat = 40
    private let activeSize: CGFloat = 70
    private let matInset: CGFloat = 3
    /// How far above the row's baseline each tier hangs. The focused thumbnail comes all the way
    /// down, its two neighbours ride highest, and the rest of the row sits between the two — so the
    /// row steps *down* going outward from the centre rather than up. That direction matters: lifting
    /// the outer tiles highest is what made the row read as centred rather than as standing on a
    /// shelf, because the small tiles then floated furthest from the line they share.
    private let neighbourLift: CGFloat = 9.5
    private let restLift: CGFloat = 8
    private let spacing: CGFloat = 10
    /// How far a thumbnail's photo slides inside its own tile at a full page away from centre.
    private let parallaxRange: CGFloat = 7

    /// Corner radius as a fraction of a thumbnail's edge, so every size shares one shape.
    private static let cornerRatio: CGFloat = 0.21

    /// Just past what it takes to clear the row, its bottom padding and the home indicator. Kept
    /// close to that minimum on purpose: a thumbnail is only visible for the part of its travel that
    /// happens above the screen edge, so a longer drop doesn't read as a longer animation — it just
    /// spends the settle out of sight. At this distance most of the spring is still on screen.
    private static let exitDrop: CGFloat = 136
    /// Expressed as duration and bounce rather than response and damping: it says outright how long
    /// a thumbnail takes to settle. Long enough to watch it arrive, with just enough overshoot to
    /// read as weight rather than as a wobble — which is also why `exitDrop` has margin built in.
    private static let travel = Animation.spring(duration: 0.62, bounce: 0.22)
    /// Gap between one ring of thumbnails leaving and the next, paced to `travel` — a ring should
    /// start while the ring inside it is still moving, so the row reads as one ripple rather than
    /// as twelve separate drops.
    private static let ringDelay: Double = 0.05

    /// The centred thumbnail goes first and the rest follow outward, so the movement reads as
    /// spreading from the one the viewer is looking at. Same order in both directions: leaving, the
    /// centre drops and the row empties outward; returning, the centre lands first and the others
    /// catch up. Distance is in whole thumbnails from the focused one, which is what makes the two
    /// neighbours of the centre move together as a pair, then the next two, and so on.
    private func exitDelay(_ index: Int) -> Double {
        let centre = Int(progress.rounded())
        return Double(abs(index - centre)) * Self.ringDelay
    }

    private var activeOuter: CGFloat { activeSize + matInset * 2 }
    private var rowHeight: CGFloat { activeOuter }

    @State private var stripWidth: CGFloat = 0
    /// Where the strip sat when the current drag began, in strip points. Held for the whole gesture so
    /// the scrub is measured against a fixed origin rather than accumulating its own feedback.
    @State private var dragAnchor: CGFloat?

    /// 1 when the thumbnail's page is centred, falling linearly to 0 one page away. Every visual
    /// property below is a function of this, so the whole strip is a pure function of `progress`
    /// and needs no animation of its own — it tracks the finger frame for frame.
    ///
    /// The layout is evaluated `at` an arbitrary page rather than only at the current one, because the
    /// drag has to ask where the strip *would* sit at some other page in order to invert the mapping.
    private func focus(_ index: Int, at page: Double) -> CGFloat {
        CGFloat(max(0, 1 - abs(Double(index) - page)))
    }

    /// Edge length of thumbnail `index`, in three tiers. Piecewise linear rather than one ramp, so
    /// the neighbours either side of the focused image hold a distinct middle size instead of being
    /// the same as the rest of the row. Still a continuous function of a fractional page — the tiers
    /// are what you see at rest, not states the strip snaps between mid-drag.
    private func side(_ index: Int, at page: Double) -> CGFloat {
        let d = abs(Double(index) - page)
        if d >= 2 { return restSize }
        if d >= 1 { return mediumSize + (restSize - mediumSize) * CGFloat(d - 1) }
        return activeSize + (mediumSize - activeSize) * CGFloat(d)
    }

    /// How far thumbnail `index` rides above the baseline, in the same three tiers as `side` and
    /// continuous at the same breakpoints — so a half-finished swipe interpolates the lift as the tile
    /// focuses instead of stepping between tiers.
    private func lift(_ index: Int, at page: Double) -> CGFloat {
        let d = abs(Double(index) - page)
        if d >= 2 { return restLift }
        if d >= 1 { return neighbourLift + (restLift - neighbourLift) * CGFloat(d - 1) }
        return neighbourLift * CGFloat(d)
    }

    /// The slot a thumbnail occupies in the row: its own edge, plus the mat once it starts to focus.
    private func width(_ index: Int, at page: Double) -> CGFloat {
        side(index, at: page) + matInset * 2 * focus(index, at: page)
    }

    /// How far the photo sits from the middle of its own tile: pushed the way the tile is offset from
    /// centre, so photos lean outward on both sides and swing back to square as their tile arrives.
    /// Signed, unlike `focus`, which is why it can't be derived from it.
    private func drift(_ index: Int, at page: Double) -> CGFloat {
        CGFloat(min(max(Double(index) - page, -1), 1)) * parallaxRange
    }

    /// Distance from the strip's leading edge to the centre of thumbnail `index`.
    private func centre(_ index: Int, at page: Double) -> CGFloat {
        var x: CGFloat = 0
        for i in 0..<index { x += width(i, at: page) + spacing }
        return x + width(index, at: page) / 2
    }

    /// The centre of the fractional position under the viewer, so a half-finished swipe parks the
    /// strip half way between two thumbnails.
    private func focusedCentre(at page: Double) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        let clamped = min(max(page, 0), Double(items.count - 1))
        let lower = Int(clamped.rounded(.down))
        let upper = min(lower + 1, items.count - 1)
        let t = CGFloat(clamped - Double(lower))
        return centre(lower, at: page) + (centre(upper, at: page) - centre(lower, at: page)) * t
    }

    /// The inverse of `focusedCentre(at:)`: which page puts `target` under the viewer. Tiles change
    /// width as focus moves, so there is no constant points-per-page to divide by — but the mapping is
    /// monotonic, which is all a bisection needs. Twelve items makes this a few hundred ops a frame.
    private func page(forCentre target: CGFloat) -> Double {
        guard items.count > 1 else { return 0 }
        var low = 0.0
        var high = Double(items.count - 1)
        if target <= focusedCentre(at: low) { return low }
        if target >= focusedCentre(at: high) { return high }
        for _ in 0..<24 {
            let mid = (low + high) / 2
            if focusedCentre(at: mid) < target { low = mid } else { high = mid }
        }
        return (low + high) / 2
    }

    /// Dragging the strip left pulls later items toward the viewer, which is the same direction the
    /// content itself moves — so the finger stays glued to the thumbnail it grabbed.
    private var scrub: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let anchor = dragAnchor ?? focusedCentre(at: progress)
                if dragAnchor == nil { dragAnchor = anchor }
                onScrub(page(forCentre: anchor - value.translation.width))
            }
            .onEnded { value in
                let anchor = dragAnchor ?? focusedCentre(at: progress)
                dragAnchor = nil
                // Carry the fling: settle on wherever the throw was headed, not where it was released.
                let predicted = page(forCentre: anchor - value.predictedEndTranslation.width)
                onSettle(min(max(Int(predicted.rounded()), 0), items.count - 1))
            }
    }

    var body: some View {
        // The row of thumbnails is far wider than the screen, so it hangs in an overlay: an overlay
        // never reports its size back to its parent, whereas a plain HStack would push that width up
        // through the ZStack and shove the chrome buttons off either edge.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
            .overlay(alignment: .leading) {
                HStack(spacing: spacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let f = focus(index, at: progress)
                        thumbnail(item, side: side(index, at: progress), focus: f, drift: drift(index, at: progress))
                            .frame(width: width(index, at: progress), height: rowHeight, alignment: .bottom)
                            .offset(y: -lift(index, at: progress))
                            .contentShape(Rectangle())
                            .onTapGesture { onSettle(index) }
                            // Each thumbnail carries its own copy of the exit, on its own clock. The
                            // offset is applied per item rather than to the row, which is the only way
                            // they can be staggered — one offset on the HStack moves them in lockstep.
                            .offset(y: isPresented ? 0 : Self.exitDrop)
                            // Scoped to `isPresented` alone, so it governs the drop and nothing else.
                            // Without it the ambient animation from the chrome toggle would drive all
                            // twelve at once, and scrubbing the strip would inherit the delays.
                            .animation(Self.travel.delay(exitDelay(index)), value: isPresented)
                    }
                }
                .fixedSize()
                .offset(x: stripWidth / 2 - focusedCentre(at: progress))
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { stripWidth = $0 }
            // On the composed view, so a drag that starts on a thumbnail hanging outside the row's
            // own bounds is still picked up.
            .contentShape(Rectangle())
            .gesture(scrub)
            // Parked off screen it is still mounted, so it would otherwise keep swallowing taps and
            // drags along the bottom of the immersive view.
            .allowsHitTesting(isPresented)
    }

    private func thumbnail(_ item: GalleryItem, side: CGFloat, focus: CGFloat, drift: CGFloat) -> some View {
        let inset = matInset * focus

        // The photo's radius scales with the photo, and the mat's is that plus the mat's own width —
        // the two curves stay exactly concentric, so the outline is always the photo's shape scaled up
        // rather than a fixed radius that rounds off into a circle as the tile shrinks.
        let photoRadius = side * Self.cornerRatio
        let mat = RoundedRectangle(cornerRadius: photoRadius + inset, style: .continuous)

        // The tile is an empty square that the photo sits inside and slides within, rather than the
        // photo itself — that separation is what lets the photo drift while the tile holds its place.
        return Color.clear
            .frame(width: side, height: side)
            .overlay(
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    // Overscanned by the drift on each side, so sliding never pulls a bare edge into view.
                    .frame(width: side + parallaxRange * 2, height: side + parallaxRange * 2)
                    .offset(x: drift)
            )
            .clipShape(RoundedRectangle(cornerRadius: photoRadius, style: .continuous))
            .padding(inset)
            .background(
                mat.fill(GalleryColor.raisedSurface)
                    .opacity(focus)
                    .shadow(color: .black.opacity(0.16 * focus), radius: 3, y: 2)
            )
            .overlay(mat.strokeBorder(GalleryColor.ink, lineWidth: focus))
    }
}


#Preview("Chrome visible") {
    GalleryDetailView(items: GalleryItem.sampleItems, startIndex: 4)
}

#Preview("Chrome hidden") {
    GalleryDetailView(items: GalleryItem.sampleItems, startIndex: 3, startChromeVisible: false)
}
