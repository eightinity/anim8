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

            dots.append(QRDot(row: r, col: c, color: color, avatarImageName: avatarImageName, cylIndex: 0))
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
            cylIndex: slot
        )
    }
    return dots
}

/// Cubic ease-with-overshoot, used to blend the flat grid into its cylinder
/// slot with a little spring-like bounce.
private func easeOutBack(_ x: CGFloat) -> CGFloat {
    let c1: CGFloat = 1.70158
    let c3 = c1 + 1
    let t = x - 1
    return 1 + c3 * t * t * t + c1 * t * t
}

/// Ease-out cubic — starts moving immediately (no zero-velocity hesitation),
/// settles gently with no overshoot. Used to collapse back into the flat grid.
private func easeOutCubic(_ x: CGFloat) -> CGFloat {
    1 - pow(1 - x, 3)
}

/// Layout constants that don't change frame to frame, computed once per
/// `GeometryReader` pass instead of per dot.
private struct QRGeometryContext {
    let gridSize: Int
    let centerRowIndex: Int
    let centerRow: CGFloat
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
    let rowStagger: TimeInterval
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
    let frontFade = max(0, min(1, (depth + 0.10) / 0.55))
    // Dots with no slot on the drum fade away entirely as it forms.
    let colOpacity = onDrum ? Double(frontFade) : 0

    let flatSize = geo.cell * 0.48
    let expandedSize = anim.baseCircleSize

    let rowDelay = Double(abs(dot.row - geo.centerRowIndex)) * anim.rowStagger

    // Grow into the cylinder, bouncing slightly as it lands.
    let forwardLocal = anim.cycleTime - anim.tFlatEnd - rowDelay
    let forwardT = max(0, min(1, forwardLocal / anim.morphDuration))
    let forwardEased = forwardLocal <= 0 ? 0 : easeOutBack(CGFloat(forwardT))

    // Collapse back to the flat grid, moving immediately.
    let backwardLocal = anim.cycleTime - anim.tHoldEnd - rowDelay
    let backwardT = max(0, min(1, backwardLocal / anim.morphDuration))
    let backwardEased = backwardLocal <= 0 ? 0 : easeOutCubic(CGFloat(backwardT))

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

struct _5FunnyQR: View {
    private static let gridSize = 21
    /// The cylinder's uniform lattice. Only `cylRows * cylCols` of the QR's
    /// dots make it onto the drum — the rest fade out as it forms — and with
    /// the back face hidden, roughly half of those are on screen at a time.
    private static let cylRows = 14
    private static let cylCols = 11
    private let dots = makeFunnyQRDots(gridSize: gridSize)
    private let centerRowIndex = gridSize / 2

    private let flatHold: TimeInterval = 3.0
    private let cylinderHold: TimeInterval = 9.0
    private let morphDuration: TimeInterval = 1.1
    private let rowStagger: TimeInterval = 0.02
    /// Radians per second the drum spins while it's expanded (negative = spins left).
    private let rotationSpeed: CGFloat = -.pi / 4
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

    /// How long the outermost row's staggered morph takes to catch up.
    private var maxRowDelay: TimeInterval { rowStagger * Double(centerRowIndex) }
    private var morphPhase: TimeInterval { morphDuration + maxRowDelay }
    private var tFlatEnd: TimeInterval { flatHold }
    private var tForwardEnd: TimeInterval { tFlatEnd + morphPhase }
    private var tHoldEnd: TimeInterval { tForwardEnd + cylinderHold }
    private var totalCycle: TimeInterval { tHoldEnd + morphPhase }

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
                centerRowIndex: centerRowIndex,
                centerRow: CGFloat(Self.gridSize - 1) / 2,
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
                let angleOffset = CGFloat(rotationClock) * rotationSpeed

                let animContext = QRAnimationContext(
                    cycleTime: cycleTime,
                    angleOffset: angleOffset,
                    tFlatEnd: tFlatEnd,
                    tHoldEnd: tHoldEnd,
                    rowStagger: rowStagger,
                    morphDuration: morphDuration,
                    baseCircleSize: baseCircleSize
                )

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
            }
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.98).ignoresSafeArea())
        .onAppear {
            startDate = Date()
        }
    }
}

#Preview {
    _5FunnyQR()
}
