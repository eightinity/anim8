//
//  _5FunnyQR.swift
//  anim8-(iOS)
//
//  Created by Gunjan Haldar   on 23/07/26.
//

import SwiftUI 

private struct QRDot: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    let color: Color
    let avatarImageName: String?
    /// Slot this dot takes on the cylinder's own uniform lattice. The QR's
    /// grid is full of gaps, so reusing (row, col) out there would give a
    /// ragged, patchy drum — the cylinder gets its own evenly-spaced
    /// numbering instead, and only the first `cylRows * cylCols` dots land
    /// on it at all.
    let cylIndex: Int
    /// How far out from the middle of the QR this dot sits, 0 at the very
    /// centre and 1 out at the farthest corner. This is the pinch point: the
    /// grid is treated like a square of cloth caught in the middle and lifted,
    /// and this fraction is what orders the dots as the lift travels outward.
    /// Straight-line distance, not row distance — a pinch spreads as a ring,
    /// so a dot off to the side is as "late" as one directly below.
    let pinchFraction: Double
}

private func makeFunnyQRDots(gridSize: Int) -> [QRDot] {
    func inFinder(_ r: Int, _ c: Int, originR: Int, originC: Int) -> Bool {
        let rr = r - originR, cc = c - originC
        guard rr >= 0, rr <= 6, cc >= 0, cc <= 6 else { return false }
        if rr == 0 || rr == 6 || cc == 0 || cc == 6 { return true }
        return (2...4).contains(rr) && (2...4).contains(cc)
    }

    func isFinder(_ r: Int, _ c: Int) -> Bool {
        inFinder(r, c, originR: 0, originC: 0)
            || inFinder(r, c, originR: 0, originC: gridSize - 7)
            || inFinder(r, c, originR: gridSize - 7, originC: 0)
    }

    func inQuietZone(_ r: Int, _ c: Int) -> Bool {
        func near(_ originR: Int, _ originC: Int) -> Bool {
            r >= originR - 1 && r <= originR + 7 && c >= originC - 1 && c <= originC + 7
                && !inFinder(r, c, originR: originR, originC: originC)
        }
        return near(0, 0) || near(0, gridSize - 7) || near(gridSize - 7, 0)
    }

    let lightBlue = Color(red: 0.68, green: 0.79, blue: 0.94)
    let midBlue = Color(red: 0.42, green: 0.56, blue: 0.86)
    let darkBlue = Color(red: 0.20, green: 0.32, blue: 0.66)

    // The pinch point, and the distance from it out to a corner — the longest
    // any dot has to wait for the lift to reach it.
    let midpoint = Double(gridSize - 1) / 2
    let cornerDistance = (midpoint * midpoint * 2).squareRoot()

    var dots: [QRDot] = []
    for r in 0..<gridSize {
        for c in 0..<gridSize {
            let onFinder = isFinder(r, c)
            var isOn = onFinder
            if !onFinder && !inQuietZone(r, c) {
                let hash = r * 928371 + c * 68917 + 12345
                isOn = (hash % 5) < 4
            }
            guard isOn else { continue }

            let hash2 = r * 4111 + c * 733
            let color: Color
            if onFinder {
                // Keeps the three corner squares reading as solid blocks
                // while the code is flat.
                color = darkBlue
            } else {
                switch hash2 % 3 {
                case 0: color = lightBlue
                case 1: color = midBlue
                default: color = darkBlue.opacity(0.75)
                }
            }
            // Every dot carries an avatar — it only shows once the drum has
            // formed, so the flat code still reads as a plain QR.
            let avatarImageName = hash2 % 2 == 0 ? "AvatarFemale" : "AvatarMale"

            let dr = Double(r) - midpoint, dc = Double(c) - midpoint
            let pinchFraction = min(1, (dr * dr + dc * dc).squareRoot() / cornerDistance)

            dots.append(QRDot(
                row: r,
                col: c,
                color: color,
                avatarImageName: avatarImageName,
                cylIndex: 0,
                pinchFraction: pinchFraction
            ))
        }
    }

    // Hand out cylinder slots in a scrambled (but fixed) order. Numbering
    // them in QR order would make the dots that don't fit on the drum all
    // come from the bottom of the code, so the QR would look like it was
    // being erased from the bottom up; scattering keeps the ones that drop
    // out spread evenly over the whole square.
    let order = dots.indices.sorted { a, b in
        let ka = (dots[a].row * 7919 + dots[a].col * 104729) % 100003
        let kb = (dots[b].row * 7919 + dots[b].col * 104729) % 100003
        return ka == kb ? a < b : ka < kb
    }
    for (slot, index) in order.enumerated() {
        let d = dots[index]
        dots[index] = QRDot(
            row: d.row,
            col: d.col,
            color: d.color,
            avatarImageName: d.avatarImageName,
            cylIndex: slot,
            pinchFraction: d.pinchFraction
        )
    }
    return dots
}

/// Smooth blend from 0 to 1, used for both halves of the morph.
///
/// This is the quintic smoothstep, and it is chosen over the more usual cubic
/// for one reason: it is flat in both its first *and* second derivative at each
/// end. Velocity starting at zero is what stops a dot looking flicked; the
/// acceleration also starting at zero is what stops the departure looking like
/// it was struck. In between it is one continuous swell with no overshoot at
/// all, so nothing is ever thrown past its target and pulled back.
private func smoothMorph(_ x: CGFloat) -> CGFloat {
    let t = min(1, max(0, x))
    return t * t * t * (t * (t * 6 - 15) + 10)
}

/// Layout constants that don't change frame to frame, computed once per
/// `GeometryReader` pass instead of per dot.
private struct QRGeometryContext {
    let gridSize: Int
    let side: CGFloat
    let cell: CGFloat
    let center: CGPoint
    let usableHeight: CGFloat
    let drumRadius: CGFloat
    let cylinderTiltAngle: CGFloat
    /// The cylinder's own uniform lattice — evenly spaced rows and evenly
    /// spaced columns around the circumference.
    let cylRows: Int
    let cylCols: Int
    /// How far each row is rotated relative to the one below it, in columns.
    /// A half-column shift stops rows stacking into hard vertical stripes
    /// and gives the drum its diagonal weave.
    let helixTwist: CGFloat
    /// How far the drum's spine leans off upright, sweeping the rows
    /// sideways so the whole column of rings runs low-left to high-right.
    let spineLeanAngle: CGFloat
    /// How far the spine bows left of dead straight at its midpoint, so it
    /// traces a curve rather than a ruler-straight diagonal.
    let spineBow: CGFloat
    /// How far each end of the spine curls back *against* the lean, turning
    /// the single diagonal into an S: the top swings on toward the top-left
    /// and the bottom toward the bottom-right.
    let spineSCurl: CGFloat
    /// How tightly that curl is packed into the two ends. Higher keeps the
    /// middle of the spine on its original diagonal and confines the counter-
    /// curve to the last stretch at each rim.
    let spineSCurlExponent: CGFloat
}

/// Timing constants for the current animation frame.
private struct QRAnimationContext {
    let cycleTime: TimeInterval
    let angleOffset: CGFloat
    let tFlatEnd: TimeInterval
    let tHoldEnd: TimeInterval
    /// The full spread between the first dot to move and the last. Both the
    /// lift and the settle use the whole of it — they just hand it out in
    /// opposite order.
    let maxStagger: TimeInterval
    let morphDuration: TimeInterval
    let baseCircleSize: CGFloat
}

private struct QRDotLayout {
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let zIndex: Double
    let mix: Double
}

/// All of the per-dot geometry/animation math, pulled out of the ForEach's
/// ViewBuilder closure and into a plain function. SwiftUI type-checks a
/// ViewBuilder closure's body as one big expression, so a couple dozen
/// chained `let`s of trig/pow math in there makes that type-check
/// exponentially slower — slow enough that Xcode Previews' build "thunk"
/// times out even though a full app build succeeds fine. A plain function
/// type-checks statement by statement and has none of that cost.
private func layoutFor(
    _ dot: QRDot,
    geo: QRGeometryContext,
    anim: QRAnimationContext
) -> QRDotLayout {
    let flatPoint = CGPoint(
        x: geo.center.x - geo.side / 2 + geo.cell / 2 + CGFloat(dot.col) * geo.cell,
        y: geo.center.y - geo.side / 2 + geo.cell / 2 + CGFloat(dot.row) * geo.cell
    )

    // The cylinder is a plain uniform drum: one fixed radius top to bottom,
    // evenly spaced rows, evenly spaced columns. Every dot reads its slot
    // off the cylinder's own lattice rather than off its QR cell.
    let slotCount = geo.cylRows * geo.cylCols
    let onDrum = dot.cylIndex < slotCount
    let slot = dot.cylIndex % max(1, slotCount)
    let cylRow = slot / geo.cylCols
    let cylCol = slot % geo.cylCols

    // -1 at the top row, +1 at the bottom, evenly stepped in between.
    let halfSpan = CGFloat(max(1, geo.cylRows - 1)) / 2
    let normalizedRow = (CGFloat(cylRow) - halfSpan) / halfSpan

    // Each column sits at its own angle around the drum's circumference,
    // plus a per-row twist so rows don't stack into vertical stripes;
    // angleOffset spins the whole cylinder around the vertical axis.
    let rowPhase = 2 * CGFloat.pi * geo.helixTwist * CGFloat(cylRow) / CGFloat(geo.cylCols)
    let colAngle = (2 * CGFloat.pi * CGFloat(cylCol) / CGFloat(geo.cylCols)) + rowPhase + anim.angleOffset
    let depth = cos(colAngle) // 1 = facing viewer, -1 = round the back

    // Hourglass silhouette: pinched at the vertical center and flaring out
    // toward the top and bottom, instead of one straight-sided tube. The
    // squared curve keeps the tangent flat right at the waist so each side
    // traces one smooth "C" — a linear step would meet in a sharp corner
    // at the center. Row *spacing* stays perfectly uniform; only the radius
    // varies.
    // The waist factor is what sets the spacing between neighbouring
    // circles at the pinch — the smallest ring is where columns crowd
    // closest — so the flare is opened up by raising the edge alone and
    // leaving the waist where it is.
    let waistFactor: CGFloat = 0.75
    // Opened up so the two rims spill past the screen edges and the drum
    // reads as filling the frame rather than sitting inside it. Only the
    // edge moves — the waist stays put, so the circles at the pinch keep
    // their spacing and the flare gets deeper rather than the whole tube
    // getting fatter.
    let edgeBoost: CGFloat = 2.15
    let rowRadiusFactor = waistFactor + (edgeBoost - waistFactor) * pow(abs(normalizedRow), 2)
    let rowDrumRadius = geo.drumRadius * rowRadiusFactor

    let localX = rowDrumRadius * sin(colAngle)
    let localY = normalizedRow * (geo.usableHeight / 2)

    // The spine — the line the ring centers sit on — is not upright. It
    // sweeps from low on the left up to high on the right, and bows a little
    // left of dead straight as it passes the middle, so it reads as a curve
    // rather than a ruled diagonal. `normalizedRow` is -1 at the top row, so
    // negating it puts the top of the sweep on the right.
    let spineSweep = -normalizedRow * (geo.usableHeight / 2) * tan(geo.spineLeanAngle)
    let spineCurve = -geo.spineBow * (1 - normalizedRow * normalizedRow)

    // Then curl each end back the other way, so the spine reads as an S
    // instead of one straight lean: the top rim carries on past upright into
    // the top-left, the bottom rim into the bottom-right. The odd power is
    // what makes it a curl and not just a weaker lean — through the middle
    // rows it contributes almost nothing, so the diagonal survives there
    // intact, and it only takes hold over the last stretch before each rim.
    // Sign is applied by hand rather than by feeding a negative base to
    // `pow`, which keeps the exponent free to be non-integral.
    let curlMagnitude = pow(abs(normalizedRow), geo.spineSCurlExponent)
    let spineCurl = geo.spineSCurl * curlMagnitude * (normalizedRow < 0 ? -1 : 1)

    // Slope the rows themselves on top of that. This is a shear, not a
    // rotation: it tips each ring by the angle without moving any circle
    // sideways, so it costs vertical space only and leaves the whole
    // horizontal budget to the radius and the spine sweep.
    let tiltedX = localX + spineSweep + spineCurve + spineCurl
    let tiltedY = localY + localX * tan(geo.cylinderTiltAngle)

    let cylinderPoint = CGPoint(
        x: geo.center.x + tiltedX,
        y: geo.center.y + tiltedY
    )

    // Only the front face of the drum is drawn. As a dot rotates past the
    // side it fades right out and stays gone the whole time it's round the
    // back, instead of showing through the front of the cylinder.
    //
    // The fade is eased rather than a straight ramp, and that is what keeps
    // the revolution from looking stepped. Depth is a cosine, so its rate of
    // change per degree of turn is at its greatest right at the silhouette —
    // exactly where a clamped linear ramp hits its corner. A dot therefore
    // used to ease in gently and then get chopped off at full speed, twice
    // per turn, across every dot on the drum. Smoothing the ramp puts a zero
    // rate at both ends, so a dot arrives and leaves without a catch.
    let frontFade = smoothMorph((depth + 0.10) / 0.55)
    // Dots with no slot on the drum fade away entirely as it forms.
    let colOpacity = onDrum ? Double(frontFade) : 0

    let flatSize = geo.cell * 0.48
    let expandedSize = anim.baseCircleSize

    // Pinch the cloth in the middle and lift: the centre comes away first and
    // the lift travels outward, so a dot's wait is its distance from the pinch.
    let liftDelay = dot.pinchFraction * anim.maxStagger
    // Laying it back down runs the other way round. The outer edge is what
    // reaches the surface first and the pinched centre is the last thing to
    // drop, so the same spread is handed out in reverse — a dot that led the
    // lift trails the settle. Sharing one `maxStagger` between the two is what
    // keeps them mirror images rather than two loosely related sweeps.
    let settleDelay = (1 - dot.pinchFraction) * anim.maxStagger

    // Ease up into the cylinder. Both halves of the morph use the same curve on
    // purpose — the lift used to overshoot its slot and snap back, and the
    // collapse used to leave at full speed, which between them are what made the
    // dots look thrown rather than carried.
    let forwardLocal = anim.cycleTime - anim.tFlatEnd - liftDelay
    let forwardT = max(0, min(1, forwardLocal / anim.morphDuration))
    let forwardEased = forwardLocal <= 0 ? 0 : smoothMorph(CGFloat(forwardT))

    // Settle back into the flat grid.
    let backwardLocal = anim.cycleTime - anim.tHoldEnd - settleDelay
    let backwardT = max(0, min(1, backwardLocal / anim.morphDuration))
    let backwardEased = backwardLocal <= 0 ? 0 : smoothMorph(CGFloat(backwardT))

    let posMix = forwardEased * (1 - backwardEased)
    let mix = min(1, max(0, posMix))

    let position = CGPoint(
        x: flatPoint.x + (cylinderPoint.x - flatPoint.x) * posMix,
        y: flatPoint.y + (cylinderPoint.y - flatPoint.y) * posMix
    )
    let size = flatSize + (expandedSize - flatSize) * mix
    let opacity = 1 + (colOpacity - 1) * mix

    return QRDotLayout(
        position: position,
        size: size,
        opacity: opacity,
        zIndex: mix > 0 ? Double(depth) : 0,
        mix: Double(mix)
    )
}

/// The four things that happen in one cycle.
///
/// Haptics are driven off changes to this rather than off `cycleTime` directly,
/// and that indirection is the whole trick: the timeline body re-runs sixty
/// times a second, so a test like `cycleTime >= tFlatEnd` is true on every one
/// of the hundred-odd frames that follow the lift, not just the first. Reducing
/// the clock to a phase first means "the phase changed" is the thing being
/// watched, and that happens exactly once per boundary.
private enum QRCyclePhase: Equatable {
    /// The QR is lying flat and readable.
    case flat
    /// Dots are peeling off the grid and gathering into the drum.
    case lifting
    /// The drum is formed and turning.
    case spinning
    /// Dots are dropping back down onto the grid.
    case settling
}

struct _5FunnyQR: View {
    /// Backdrop, and the colour the top and bottom scrims fade *from*. One
    /// constant feeds both on purpose: the scrims only read as the drum
    /// dissolving into nothing if they land on exactly the page colour, and
    /// this is very nearly white but not actually white — a scrim fading to
    /// `.white` would leave a lighter band along each edge.
    private static let backgroundColor = Color(red: 0.96, green: 0.97, blue: 0.98)
    /// How much of the screen's height each scrim covers. The flared rims are
    /// the sparsest part of the drum, so fading them is also what stops the
    /// two ends reading as scattered loose circles.
    private static let edgeFadeFraction: CGFloat = 0.20

    private static let gridSize = 21
    /// The cylinder's uniform lattice. Only `cylRows * cylCols` of the QR's
    /// dots make it onto the drum — the rest fade out as it forms — and with
    /// the back face hidden, roughly half of those are on screen at a time.
    private static let cylRows = 14
    private static let cylCols = 11
    private let dots = makeFunnyQRDots(gridSize: gridSize)

    private let flatHold: TimeInterval = 3.0
    private let cylinderHold: TimeInterval = 9.0
    /// How long any one dot takes to make its own trip. Shortened, because the
    /// stagger below now spreads the dots out in time — leaving this at its old
    /// length would have every dot still travelling when the last one sets off,
    /// which reads as a slow blur rather than a wave passing through.
    private let morphDuration: TimeInterval = 0.9
    /// Gap between the first dot to move and the last. This used to be a
    /// per-row 0.02, about 0.2s end to end against a 1.1s trip — far too little
    /// to see, which is why the grid looked like it moved all at once.
    private let maxStagger: TimeInterval = 0.8
    /// Radians per second the drum spins while it's expanded (negative = spins left).
    private let rotationSpeed: CGFloat = -.pi / 4
    /// Time constant for the drum getting up to that speed. At 1.2s it is about
    /// three quarters of the way there by the time the morph finishes, so the
    /// drum is visibly gathering pace while it forms rather than already flat
    /// out, and is at full rate well inside the hold.
    private let spinUpTau: TimeInterval = 1.2
    /// How far each ring is tipped. Applied as a shear, so it costs vertical
    /// space only and never squeezes the flared top and bottom rows.
    /// Kept well clear of the spine's lean below — when the two angles match
    /// the rings line up with the spine and the drum reads as a flat ribbon
    /// instead of a tube.
    private let cylinderTiltAngle: CGFloat = -6 * .pi / 180
    /// How far the spine — the line the ring centers sit on — leans off
    /// upright, sweeping the drum from low-left to high-right. Unlike the
    /// ring tip above, this one does move circles sideways, so it's paid for
    /// out of the same horizontal budget as the radius.
    private let spineLeanAngle: CGFloat = 12 * .pi / 180
    /// How hard each end of the spine curls back against that lean. Expressed
    /// as an angle over the same spine length the lean uses, so the curl and
    /// the thing it's fighting are always drawn from one budget: change the
    /// screen, the drum's proportions, or `usableHeight`, and the two move
    /// together instead of drifting out of step. It has to out-run the lean to
    /// read as a curl at all, hence the larger angle.
    private let spineCurlAngle: CGFloat = 23.4 * .pi / 180
    /// Blows the whole drum up without touching its shape. It multiplies the
    /// drum's width and its spine length by the same amount, and every other
    /// sideways term — radius, spine lean, bow, curl, circle size — is already
    /// measured off one of those two, so they all follow in step and the
    /// silhouette comes out identical, just larger.
    ///
    /// Past about 1.12 the widest rings start running off the sides. That is
    /// unavoidable rather than a mistake: the silhouette is proportionally
    /// wider than the screen is, so filling the height at all means letting
    /// the two flared ends bleed past the edges.
    private static let structureScale: CGFloat = 1.35

    /// One whole sweep: the last dot's wait plus its own trip.
    private var morphPhase: TimeInterval { morphDuration + maxStagger }
    private var tFlatEnd: TimeInterval { flatHold }
    private var tForwardEnd: TimeInterval { tFlatEnd + morphPhase }
    private var tHoldEnd: TimeInterval { tForwardEnd + cylinderHold }
    private var totalCycle: TimeInterval { tHoldEnd + morphPhase }

    /// Whether the cycle taps out its turning points.
    ///
    /// Worth knowing what this switches on: there is nothing to tap on this
    /// screen, so the feedback is not answering a gesture — it fires on its own
    /// every `totalCycle` seconds for as long as the view is up. That is a
    /// deliberate choice for an ambient piece and not the usual reason to reach
    /// for haptics, so it is kept behind one flag rather than being woven in.
    private let hapticsEnabled = true

    @State private var startDate: Date?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.6

            // Expanded layout is smaller than the full screen. The spine's
            // lean throws whole rows sideways on top of the drum's own
            // radius, so the radius has to leave room for that sweep or the
            // drum runs off both edges of the screen. At 16° over a 0.62·H
            // spine the sweep is about 0.14·W each way, which is what the
            // radius here has been cut back to pay for.
            // Trimmed a little past what the lean alone needs, because the
            // spine's S-curl throws the two rims further sideways still — and
            // they're the widest rings on the drum, so they're what reaches the
            // screen edge first. The radius pays for that headroom.
            let usableWidth = geo.size.width * 0.405 * Self.structureScale

            // Hoisted out of the context below so the spine's sideways terms
            // can be measured against the same span the lean is.
            let usableHeight = geo.size.height * 0.62 * Self.structureScale
            let halfSpine = usableHeight / 2

            let geoContext = QRGeometryContext(
                gridSize: Self.gridSize,
                side: side,
                cell: side / CGFloat(Self.gridSize),
                center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                usableHeight: usableHeight,
                drumRadius: usableWidth / 2,
                cylinderTiltAngle: cylinderTiltAngle,
                cylRows: Self.cylRows,
                cylCols: Self.cylCols,
                helixTwist: 0.5,
                spineLeanAngle: spineLeanAngle,
                // Both of these used to be cut from the screen's *width*, while
                // the lean they work against is cut from its height — so on a
                // shorter, narrower phone they drifted out of proportion and
                // the rims crowded the edge. All three sideways terms now come
                // off the same spine length.
                //
                // The bow is also dialled well back from what it was: it pulls
                // the middle left, which is the same direction the top half's
                // curl is trying to travel, so at its old strength it swallowed
                // the curl and the top end came out nearly straight.
                spineBow: halfSpine * 0.0415,
                spineSCurl: halfSpine * tan(spineCurlAngle),
                spineSCurlExponent: 3
            )
            // Size the drum's circles off its own column spacing, not the
            // QR's, so they sit apart cleanly at the front of the drum. The
            // multiplier is set so a circle is comfortably narrower than the
            // gap between neighbours even at the pinched waist, where the
            // ring is at its smallest and the columns crowd closest.
            let baseCircleSize = (usableWidth / CGFloat(Self.cylCols)) * 1.65

            TimelineView(.animation) { timeline in
                let elapsed = startDate.map { timeline.date.timeIntervalSince($0) } ?? 0
                let cycleTime = elapsed.truncatingRemainder(dividingBy: totalCycle)

                // Rotation never stops or freezes — it keeps spinning right
                // through the backward morph too. Position is a separate
                // blend (mix) down to the flat grid, so by the time the
                // collapse finishes the still-spinning angle no longer
                // matters; nothing snaps or halts along the way.
                let rotationClock = max(0, cycleTime - tFlatEnd)
                // The drum winds up to speed instead of switching on at full
                // tilt. It used to jump from stationary to its whole rate in a
                // single frame, which meant every dot was morphing into a slot
                // that was already sweeping sideways at over a screen width a
                // second out at the rims — the dots arrived, but never arrived
                // at rest. Ramping the rate as `v = vmax(1 - e^(-t/tau))` lets
                // the drum gather its spin the way something with mass would.
                //
                // What is written here is that ramp's exact integral rather
                // than the rate itself, so the *angle* is what stays smooth:
                // continuous, starting at zero rate, and asymptotically back
                // on the same constant-speed line as before.
                let spinUp = rotationClock - spinUpTau * (1 - exp(-rotationClock / spinUpTau))
                let angleOffset = CGFloat(spinUp) * rotationSpeed

                let animContext = QRAnimationContext(
                    cycleTime: cycleTime,
                    angleOffset: angleOffset,
                    tFlatEnd: tFlatEnd,
                    tHoldEnd: tHoldEnd,
                    maxStagger: maxStagger,
                    morphDuration: morphDuration,
                    baseCircleSize: baseCircleSize
                )

                // Same four boundaries the layout already runs off, collapsed
                // to a single value that only changes at the edges.
                let phase: QRCyclePhase =
                    cycleTime < tFlatEnd ? .flat
                    : cycleTime < tForwardEnd ? .lifting
                    : cycleTime < tHoldEnd ? .spinning
                    : .settling

                ZStack {
                    ForEach(dots) { dot in
                        let dotLayout = layoutFor(dot, geo: geoContext, anim: animContext)

                        ZStack {
                            Circle()
                                .fill(dot.color)
                                .frame(width: dotLayout.size, height: dotLayout.size)

                            if let avatarImageName = dot.avatarImageName, dotLayout.mix > 0.01 {
                                Image(avatarImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: dotLayout.size * 0.82, height: dotLayout.size * 0.82)
                                    .clipShape(Circle())
                            }
                        }
                        .opacity(dotLayout.opacity)
                        .position(dotLayout.position)
                        .zIndex(dotLayout.zIndex)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                // Two of the four boundaries are silent on purpose. A tap only
                // reads as belonging to the picture if there is a moment under
                // it, and the two morph *ends* are the softest instants in the
                // cycle by design — the dots arrive on a smoothstep and the
                // drum is still winding up to speed — so marking them would put
                // a hard edge exactly where the motion has none.
                .sensoryFeedback(trigger: phase) { _, phase in
                    guard hapticsEnabled else { return nil }
                    switch phase {
                    case .lifting:
                        // The grid lets go. Soft and low: the cloth is pinched
                        // and peeled away, it does not snap.
                        return .impact(flexibility: .soft, intensity: 0.5)
                    case .settling:
                        // The same event running backwards. Lighter than the
                        // lift, because this wave starts out at the rim where
                        // the drum is at its sparsest.
                        return .impact(flexibility: .soft, intensity: 0.35)
                    case .flat:
                        // Everything is down and the code is readable again.
                        // The firmest of the three, and the only one of the
                        // four boundaries that is genuinely an arrival.
                        return .impact(flexibility: .solid, intensity: 0.6)
                    case .spinning:
                        return nil
                    }
                }
            }
        }
        .background(Self.backgroundColor.ignoresSafeArea())
        // Deliberately an `overlay` rather than another layer in a ZStack:
        // overlay is sized to the view it sits on and never feeds back into
        // that view's layout, so the GeometryReader above keeps reporting the
        // safe-area-inset height the whole drum is measured against. Wrapping
        // the two in a ZStack and letting them ignore the safe area would grow
        // the reader to the full screen and quietly resize the drum with it.
        .overlay {
            GeometryReader { screen in
                let fade = screen.size.height * Self.edgeFadeFraction
                VStack(spacing: 0) {
                    LinearGradient(
                        // Fading to the same colour at zero alpha, not to
                        // `.clear`. `.clear` is transparent *black*, so
                        // interpolating towards it drags a grey cast through
                        // the middle of the ramp.
                        colors: [Self.backgroundColor, Self.backgroundColor.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: fade)

                    Spacer(minLength: 0)

                    LinearGradient(
                        colors: [Self.backgroundColor.opacity(0), Self.backgroundColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: fade)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            startDate = Date()
        }
    }
}

#Preview {
    _5FunnyQR()
}
