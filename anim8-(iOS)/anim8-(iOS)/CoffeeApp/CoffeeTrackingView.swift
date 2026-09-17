import SwiftUI
import MapKit

// MARK: - Tracking

struct CoffeeTrackingView: View {
    var onClose: () -> Void = {}

    @State private var appeared = false
    @State private var progress: CGFloat = 0.18
    @State private var status: DeliveryStatus = .onTheWay
    @State private var pulse = false

    private let storeCoordinate = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
    private let homeCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4294)
    private var courierCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: storeCoordinate.latitude + (homeCoordinate.latitude - storeCoordinate.latitude) * Double(progress),
            longitude: storeCoordinate.longitude + (homeCoordinate.longitude - storeCoordinate.longitude) * Double(progress)
        )
    }

    @State private var cameraPosition: MapCameraPosition

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
        let store = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let home = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4294)
        let center = CLLocationCoordinate2D(latitude: (store.latitude + home.latitude) / 2, longitude: (store.longitude + home.longitude) / 2)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))
        self._cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
                .ignoresSafeArea()

            topBar

            bottomSheet
        }
        .onAppear {
            CoffeeHaptics.prepare()
            withAnimation(CoffeeSpring.stagger) { appeared = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
            simulateProgress()
        }
    }

    // MARK: Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            Marker("Coffee Bar", coordinate: storeCoordinate)
                .tint(CoffeeColor.espresso)

            Marker("Home", coordinate: homeCoordinate)
                .tint(CoffeeColor.success)

            Annotation("", coordinate: courierCoordinate) {
                ZStack {
                    Circle()
                        .fill(CoffeeColor.amber.opacity(0.25))
                        .frame(width: pulse ? 46 : 30, height: pulse ? 46 : 30)
                    Circle()
                        .fill(CoffeeColor.amber)
                        .frame(width: 30, height: 30)
                    Image(systemName: "bicycle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            MapPolyline(coordinates: [storeCoordinate, homeCoordinate])
                .stroke(CoffeeColor.espresso, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 10]))
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls { }
    }

    // MARK: Top bar

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    CoffeeHaptics.tap()
                    onClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CoffeeColor.ink)
                        .frame(width: 40, height: 40)
                        .background(.white, in: Circle())
                }
                .buttonStyle(.plain)
                .coffeePressable()

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CoffeeColor.espresso)
                    Text("\(etaMinutes) min")
                        .font(.sora(.semibold, 13))
                        .foregroundStyle(CoffeeColor.ink)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, CoffeeSpacing.md)
                .frame(height: 40)
                .background(.white, in: Capsule())
            }
            .padding(.horizontal, CoffeeSpacing.lg)
            .padding(.top, CoffeeSpacing.sm)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
    }

    private var etaMinutes: Int {
        max(1, Int((1 - progress) * 18))
    }

    // MARK: Bottom sheet

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: CoffeeSpacing.md) {
            Capsule()
                .fill(CoffeeColor.divider)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)

            statusHeader

            progressBar

            statusSteps

            courierCard
        }
        .padding(CoffeeSpacing.lg)
        .padding(.bottom, CoffeeSpacing.md)
        .background(
            CoffeeColor.surface
                .clipShape(RoundedRectangle(cornerRadius: CoffeeRadius.lg, style: .continuous))
                .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: appeared ? 0 : 260)
        .animation(CoffeeSpring.gentle.delay(0.15), value: appeared)
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(status.title)
                .font(.sora(.bold, 19))
                .foregroundStyle(CoffeeColor.ink)
                .contentTransition(.opacity)
            Text(status.subtitle)
                .font(.sora(.regular, 13))
                .foregroundStyle(CoffeeColor.muted)
                .contentTransition(.opacity)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CoffeeColor.well)
                    .frame(height: 8)

                Capsule()
                    .fill(CoffeeColor.espresso)
                    .frame(width: geo.size.width * progress, height: 8)

                Circle()
                    .fill(CoffeeColor.espresso)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .offset(x: geo.size.width * progress - 8)
            }
        }
        .frame(height: 16)
    }

    private var statusSteps: some View {
        HStack {
            ForEach(DeliveryStatus.allCases) { step in
                let isDone = step.rawValue <= status.rawValue
                VStack(spacing: 6) {
                    Circle()
                        .fill(isDone ? CoffeeColor.espresso : CoffeeColor.well)
                        .frame(width: 10, height: 10)
                    Text(shortLabel(step))
                        .font(.sora(.medium, 10))
                        .foregroundStyle(isDone ? CoffeeColor.ink : CoffeeColor.faint)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(CoffeeSpring.snap, value: status)
    }

    private func shortLabel(_ step: DeliveryStatus) -> String {
        switch step {
        case .preparing: return "Prep"
        case .onTheWay: return "On Way"
        case .arriving: return "Arriving"
        case .delivered: return "Delivered"
        }
    }

    private var courierCard: some View {
        HStack(spacing: CoffeeSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [CoffeeColor.espresso, CoffeeColor.espressoDeep], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 48, height: 48)
                Text(sampleCourier.initials)
                    .font(.sora(.bold, 16))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sampleCourier.name)
                    .font(.sora(.semibold, 15))
                    .foregroundStyle(CoffeeColor.ink)
                Text(sampleCourier.vehicle)
                    .font(.sora(.regular, 12))
                    .foregroundStyle(CoffeeColor.muted)
            }

            Spacer()

            circleAction(system: "message.fill")
            circleAction(system: "phone.fill", filled: true)
        }
        .padding(CoffeeSpacing.md)
        .background(CoffeeColor.well, in: RoundedRectangle(cornerRadius: CoffeeRadius.md, style: .continuous))
    }

    private func circleAction(system: String, filled: Bool = false) -> some View {
        Button {
            CoffeeHaptics.commit()
        } label: {
            Image(systemName: system)
                .font(.system(size: 15))
                .foregroundStyle(filled ? .white : CoffeeColor.espresso)
                .frame(width: 40, height: 40)
                .background(filled ? CoffeeColor.espresso : CoffeeColor.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .coffeePressable()
    }

    // MARK: Simulation

    private func simulateProgress() {
        Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { timer in
            DispatchQueue.main.async {
                withAnimation(CoffeeSpring.gentle) {
                    progress = min(progress + 0.22, 1.0)
                }
                CoffeeHaptics.tick()

                if progress > 0.35 && status == .onTheWay {
                    withAnimation(CoffeeSpring.snap) { status = .arriving }
                    CoffeeHaptics.tap()
                }
                if progress >= 1.0 {
                    withAnimation(CoffeeSpring.bouncy) { status = .delivered }
                    CoffeeHaptics.success()
                    timer.invalidate()
                }
            }
        }
    }
}

#Preview {
    CoffeeTrackingView()
}
