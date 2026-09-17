import UIKit

/// Central haptic ladder for the coffee ordering flow.
enum CoffeeHaptics {
    private static let light    = UIImpactFeedbackGenerator(style: .light)
    private static let medium   = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy    = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigid    = UIImpactFeedbackGenerator(style: .rigid)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        medium.prepare()
        selection.prepare()
    }

    /// Tap on a small control — chips, size options, stepper buttons.
    static func tap() {
        light.impactOccurred()
        light.prepare()
    }

    /// A meaningful state change commits — add to cart, toggle deliver/pickup.
    static func commit() {
        medium.impactOccurred()
        medium.prepare()
    }

    /// A big, satisfying action lands — order placed, payment confirmed.
    static func success() {
        notification.notificationOccurred(.success)
    }

    /// Discrete scrub across values — quantity stepper, size picker slide.
    static func tick() {
        selection.selectionChanged()
        selection.prepare()
    }

    /// Firm confirmation — CTA press, arrival at destination.
    static func thud() {
        rigid.impactOccurred(intensity: 0.7)
        rigid.prepare()
    }
}
