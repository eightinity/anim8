import SwiftUI

/// Warm, near-white palette for the gallery viewer.
enum GalleryColor {
    static let ink           = Color(red: 0.12, green: 0.11, blue: 0.10)
    static let muted         = Color(red: 0.56, green: 0.53, blue: 0.51)
    static let icon          = Color(red: 0.30, green: 0.29, blue: 0.28)

    /// Pure white — the button face has to out-brighten the warm gray background to read as raised.
    static let buttonSurface = Color.white

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.925, green: 0.92, blue: 0.915),
            Color(red: 0.978, green: 0.973, blue: 0.968),
            Color(red: 0.95, green: 0.945, blue: 0.94)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension GalleryColor {
    /// Raised button face: a tight, crisp inner shadow hugging the bottom edge. The small blur radius
    /// is what keeps it reading as a sharp arc rather than a soft dome — widening it washes the white out.
    /// A *negative* y is what puts the inner shadow at the bottom — positive puts it at the top.
    static let raisedSurface = AnyShapeStyle(
        buttonSurface.shadow(.inner(color: .black.opacity(0.35), radius: 1.5, x: 0, y: -2))
    )
}
