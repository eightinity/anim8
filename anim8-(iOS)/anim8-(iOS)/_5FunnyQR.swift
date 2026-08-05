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
    /// How large/close this row appears once the grid revolves into a cylinder —
    /// rows nearest the centre face the viewer (bigger), rows near the top/bottom edge
    /// curl away (smaller), like the front of a rotating drum.
    let depthScale: CGFloat
}

private func makeFunnyQRDots(gridSize: Int) -> [QRDot] {
    let centerRow = Double(gridSize - 1) / 2
    let maxAngle = Double.pi / 2.3

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
        let normalizedRow = (Double(r) - centerRow) / centerRow
        let rowAngle = normalizedRow * maxAngle
        let depthScale = 0.55 + 0.75 * cos(rowAngle)

        for c in 0..<gridSize {
            let onFinder = isFinder(r, c)
            var isOn = onFinder
            if !onFinder && !inQuietZone(r, c) {
                let hash = r * 928371 + c * 68917 + 12345
                isOn = (hash % 5) < 2
            }
            guard isOn else { continue }

            let color: Color
            if onFinder {
                color = darkBlue
            } else {
                let hash2 = r * 4111 + c * 733
                switch hash2 % 3 {
                case 0: color = lightBlue
                case 1: color = midBlue
                default: color = darkBlue.opacity(0.75)
                }
            }

            dots.append(QRDot(row: r, col: c, color: color, depthScale: CGFloat(depthScale)))
        }
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

struct _5FunnyQR: View {
    private static let gridSize = 21
    private let dots = makeFunnyQRDots(gridSize: gridSize)
    private let centerRowIndex = gridSize / 2

    private let flatHold: TimeInterval = 3.0
    private let cylinderHold: TimeInterval = 3.0
    private let morphDuration: TimeInterval = 1.1
    private let rowStagger: TimeInterval = 0.02
    /// Radians per second the drum spins while it's expanded.
    private let rotationSpeed: CGFloat = .pi / 4

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
            let side = min(geo.size.width, geo.size.height) * 0.82
            let cell = side / CGFloat(Self.gridSize)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let centerRow = CGFloat(Self.gridSize - 1) / 2

            // Expanded layout spreads across the full screen instead of the
            // small QR footprint.
            let usableWidth = geo.size.width * 0.96
            let usableHeight = geo.size.height * 0.88
            let drumRadius = usableWidth / 2
            let baseCircleSize = (usableWidth / CGFloat(Self.gridSize)) * 1.4

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

                ZStack {
                    ForEach(dots) { dot in
                        let flatPoint = CGPoint(
                            x: center.x - side / 2 + cell / 2 + CGFloat(dot.col) * cell,
                            y: center.y - side / 2 + cell / 2 + CGFloat(dot.row) * cell
                        )

                        let normalizedRow = (CGFloat(dot.row) - centerRow) / centerRow

                        // Each column sits at its own angle around the drum's
                        // circumference; adding angleOffset spins the whole
                        // cylinder continuously around the vertical axis.
                        let colAngle = (2 * CGFloat.pi * CGFloat(dot.col) / CGFloat(Self.gridSize)) + angleOffset
                        let depth = cos(colAngle) // 1 = facing viewer, -1 = round the back

                        // Hourglass silhouette: wide at the top and bottom rows,
                        // pinched to a narrow waist in the middle, instead of a
                        // uniform-width drum.
                        let waistFactor: CGFloat = 0.55
                        let edgeBoost: CGFloat = 1.35
                        let rowRadiusFactor = waistFactor + (edgeBoost - waistFactor) * pow(abs(normalizedRow), 1.5)
                        let rowDrumRadius = drumRadius * rowRadiusFactor

                        let cylinderPoint = CGPoint(
                            x: center.x + rowDrumRadius * sin(colAngle),
                            y: center.y + normalizedRow * (usableHeight / 2)
                        )

                        // Dots swinging round the back shrink and fade, like
                        // they're receding on the far side of the cylinder.
                        let colScale = 0.675 + 0.325 * depth
                        let colOpacity = 0.65 + 0.35 * depth

                        let flatSize = cell * 0.62
                        let expandedSize = baseCircleSize * dot.depthScale * colScale

                        let rowDelay = Double(abs(dot.row - centerRowIndex)) * rowStagger

                        // Grow into the cylinder, bouncing slightly as it lands.
                        let forwardLocal = cycleTime - tFlatEnd - rowDelay
                        let forwardT = max(0, min(1, forwardLocal / morphDuration))
                        let forwardEased = forwardLocal <= 0 ? 0 : easeOutBack(CGFloat(forwardT))

                        // Collapse back to the flat grid, moving immediately.
                        let backwardLocal = cycleTime - tHoldEnd - rowDelay
                        let backwardT = max(0, min(1, backwardLocal / morphDuration))
                        let backwardEased = backwardLocal <= 0 ? 0 : easeOutCubic(CGFloat(backwardT))

                        let posMix = forwardEased * (1 - backwardEased)
                        let mix = min(1, max(0, posMix))

                        let position = CGPoint(
                            x: flatPoint.x + (cylinderPoint.x - flatPoint.x) * posMix,
                            y: flatPoint.y + (cylinderPoint.y - flatPoint.y) * posMix
                        )
                        let size = flatSize + (expandedSize - flatSize) * mix
                        let opacity = 1 + (colOpacity - 1) * mix

                        Circle()
                            .fill(dot.color)
                            .frame(width: size, height: size)
                            .opacity(opacity)
                            .position(position)
                            .zIndex(mix > 0 ? Double(depth) : 0)
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
