import SwiftUI

// MARK: - Typography

extension Font {
    static func sora(_ weight: SoraWeight, _ size: CGFloat) -> Font {
        .custom(weight.postscriptName, size: size)
    }
}

enum SoraWeight {
    case regular, medium, semibold, bold, extrabold

    var postscriptName: String {
        switch self {
        case .regular:  return "Sora"
        case .medium:   return "Sora-Medium"
        case .semibold: return "Sora-SemiBold"
        case .bold:     return "Sora-Bold"
        case .extrabold: return "Sora-ExtraBold"
        }
    }
}

// MARK: - Palette

/// Light, tonal-stack palette for the coffee ordering flow.
/// Depth comes from lightness deltas between stacked surfaces, not shadows.
enum CoffeeColor {
    static let background   = Color(red: 0.98, green: 0.965, blue: 0.95)
    static let surface      = Color.white
    static let well         = Color(red: 0.955, green: 0.945, blue: 0.925)
    static let divider      = Color(red: 0.90, green: 0.88, blue: 0.85)

    static let ink          = Color(red: 0.13, green: 0.09, blue: 0.06)
    static let muted        = Color(red: 0.55, green: 0.50, blue: 0.46)
    static let faint        = Color(red: 0.72, green: 0.68, blue: 0.64)

    /// Deep espresso — primary CTA / accent, deepened for contrast on white per light-theme rules.
    static let espresso     = Color(red: 0.24, green: 0.15, blue: 0.10)
    static let espressoDeep = Color(red: 0.15, green: 0.09, blue: 0.06)

    /// Warm amber — used for rating stars, price highlight, progress accents.
    static let amber        = Color(red: 0.82, green: 0.55, blue: 0.18)

    static let success      = Color(red: 0.30, green: 0.58, blue: 0.36)
    static let danger       = Color(red: 0.80, green: 0.32, blue: 0.30)
}

// MARK: - Spacing

enum CoffeeSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum CoffeeRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Springs

/// Named spring presets reused across the coffee flow so motion stays consistent.
enum CoffeeSpring {
    static let snap        = Animation.spring(response: 0.35, dampingFraction: 0.72)
    static let bouncy      = Animation.spring(response: 0.42, dampingFraction: 0.62)
    static let gentle      = Animation.spring(response: 0.55, dampingFraction: 0.82)
    static let quick       = Animation.spring(response: 0.28, dampingFraction: 0.78)
    static let stagger     = Animation.spring(response: 0.5, dampingFraction: 0.78)
    /// Bouncier press-release — has a touch of overshoot so a tap feels alive, not just damped.
    static let press       = Animation.spring(response: 0.32, dampingFraction: 0.55)
    /// Rubber-band pop for toasts / badges that enter oversized and settle back.
    static let pop         = Animation.spring(response: 0.45, dampingFraction: 0.58)
}

// MARK: - Press feedback

/// Scale-down-on-press modifier shared across tappable cards/buttons in the coffee flow.
/// Fires a light haptic on the press-DOWN edge (not on release) so touch feels immediate,
/// and rubber-bands back up with a touch of overshoot on release.
struct CoffeePressable: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.96
    var haptic: Bool = true

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(CoffeeSpring.press, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            if haptic { CoffeeHaptics.tap() }
                        }
                    }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func coffeePressable(scale: CGFloat = 0.96, haptic: Bool = true) -> some View {
        modifier(CoffeePressable(scale: scale, haptic: haptic))
    }
}

// MARK: - Rubber-band entrance (toast / badge pop)

private struct CoffeeWidthPop: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? 1.12 : 1.0, anchor: .top)
            .offset(y: active ? -10 : 0)
            .opacity(active ? 0 : 1)
    }
}

extension AnyTransition {
    /// Enters oversized and rubber-bands down to true size; exits by sliding up and fading.
    static var coffeeWidthPop: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: CoffeeWidthPop(active: true), identity: CoffeeWidthPop(active: false)),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
}
