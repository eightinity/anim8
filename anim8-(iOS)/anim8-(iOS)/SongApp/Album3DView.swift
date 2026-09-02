import SwiftUI
import SceneKit

// ─────────────────────────────────────────────
// MARK: - Tune these values to change the look
// ─────────────────────────────────────────────

private let albumSize:     CGFloat = 1.6    // face width & height in scene units
private let albumDepth:    CGFloat = 0.11   // sleeve thickness
private let tiltY:         Float   = 0       // degrees — left/right rotation (exposes spine)
private let cameraZ:       Float   = 5.0    // camera distance — higher = smaller on screen
private let cameraFOV:     CGFloat = 46     // field of view in degrees
private let keyIntensity:  CGFloat = 900    // main light brightness
private let ambientLevel:  CGFloat = 0.30   // fill-light level (0 = pitch-black shadows)

/// Tilt values for the 3D album — synced with carousel scroll position.
enum Album3DLayout {
    /// Front-card tilt (degrees). More negative = flatter toward the viewer.
    static let frontTiltX: Float = -100
    /// Degrees added per step for albums above the front (fan flat).
    static let aheadDegreesPerStep: Float = 6
    /// Degrees added per step for albums below the front (fan upright).
    static let behindDegreesPerStep: Float = 10

    static func tiltX(scrollProgress: CGFloat) -> Float {
        if scrollProgress < 0 {
            return frontTiltX + Float(scrollProgress) * aheadDegreesPerStep
        }
        return frontTiltX + Float(scrollProgress) * behindDegreesPerStep
    }

    static func scale(scrollProgress: CGFloat) -> CGFloat {
        let distance = abs(scrollProgress)
        return max(0.88, 1.0 - distance * 0.008)
    }

    static func opacity(scrollProgress: CGFloat) -> Double {
        let distance = abs(Double(scrollProgress))
        return max(0.45, 1.0 - distance * 0.018)
    }
}

// ─────────────────────────────────────────────

struct Album3DView: View {
    var imageName: String = "BrandNewEyes"
    var title: String = "Brand New Eyes"
    var artist: String = "Paramore"
    var tiltX: Float = Album3DLayout.frontTiltX
    /// When `true`, uses a clear background so the view can sit inside the carousel.
    var embedded: Bool = false

    var body: some View {
        Group {
            if embedded {
                sceneView
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    sceneView
                }
            }
        }
        .background(Color.clear)
    }

    private var sceneView: some View {
        TransparentSceneView(
            imageName: imageName,
            title: title,
            artist: artist,
            tiltX: tiltX,
            embedded: embedded
        )
    }
}

/// SceneKit view with a truly transparent background (SwiftUI `SceneView` defaults to white).
private struct TransparentSceneView: UIViewRepresentable {
    let imageName: String
    let title: String
    let artist: String
    var tiltX: Float
    var embedded: Bool = false

    func makeCoordinator() -> Coordinator {
        let scene = makeAlbumScene(imageName: imageName, title: title, artist: artist)
        let albumNode = scene.rootNode.childNode(withName: "album", recursively: false)!
        let cameraNode = scene.rootNode.childNodes.first { $0.camera != nil }!
        return Coordinator(scene: scene, albumNode: albumNode, cameraNode: cameraNode)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        view.allowsCameraControl = false
        view.antialiasingMode = embedded ? .multisampling2X : .multisampling4X
        applyTilt(tiltX, to: context.coordinator.albumNode)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.isOpaque = false
        uiView.backgroundColor = .clear
        uiView.layer.isOpaque = false
        uiView.pointOfView = context.coordinator.cameraNode
        applyTilt(tiltX, to: context.coordinator.albumNode)
    }

    private func applyTilt(_ tiltX: Float, to node: SCNNode) {
        SCNTransaction.begin()
        SCNTransaction.disableActions = true
        node.eulerAngles = SCNVector3Make(tiltX * .pi / 180, tiltY * .pi / 180, 0)
        SCNTransaction.commit()
    }

    final class Coordinator {
        let scene: SCNScene
        let albumNode: SCNNode
        let cameraNode: SCNNode

        init(scene: SCNScene, albumNode: SCNNode, cameraNode: SCNNode) {
            self.scene = scene
            self.albumNode = albumNode
            self.cameraNode = cameraNode
        }
    }
}

// MARK: - Scene builder

private func makeAlbumScene(
    imageName: String,
    title: String,
    artist: String
) -> SCNScene {
    let scene = SCNScene()
    scene.background.contents = nil

    // Geometry
    let box = SCNBox(width: albumSize, height: albumSize, length: albumDepth, chamferRadius: 0)

    // SCNBox element order: +Z front · -Z back · +X right · -X left · +Y top · -Y bottom
    let albumImage = UIImage(named: imageName)
    let edgeColor = dominantColor(in: albumImage) ?? UIColor(white: 0.45, alpha: 1)

    let coverFront = SCNMaterial()
    coverFront.diffuse.contents = albumImage
    coverFront.lightingModel = .blinn

    let coverRight = SCNMaterial()
    coverRight.diffuse.contents = albumImage
    coverRight.lightingModel = .constant

    func colorMaterial(_ color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .constant
        return material
    }

    let labelEdge = SCNMaterial()
    labelEdge.diffuse.contents = labeledEdgeImage(
        backgroundColor: edgeColor,
        title: title,
        artist: artist
    )
    labelEdge.lightingModel = .constant

    box.materials = [
        coverFront,              // +Z front  — image
        colorMaterial(edgeColor), // -Z back
        coverRight,              // +X right  — image
        colorMaterial(edgeColor), // -X left
        colorMaterial(edgeColor), // +Y top
        labelEdge                // -Y bottom — title + artist
    ]

    let albumNode = SCNNode(geometry: box)
    albumNode.name = "album"
    scene.rootNode.addChildNode(albumNode)

    // Camera
    let camNode = SCNNode()
    camNode.camera = SCNCamera()
    camNode.camera?.fieldOfView = cameraFOV
    camNode.position = SCNVector3Make(0, 0.3, cameraZ)
    scene.rootNode.addChildNode(camNode)

    // Key light (directional, top-front-left)
    let keyNode = SCNNode()
    keyNode.light = SCNLight()
    keyNode.light?.type = .directional
    keyNode.light?.color = UIColor.white
    keyNode.light?.intensity = keyIntensity
    keyNode.eulerAngles = SCNVector3Make(
        -40 * .pi / 180,
         25 * .pi / 180,
        0
    )
    scene.rootNode.addChildNode(keyNode)

    // Ambient fill
    let ambientNode = SCNNode()
    ambientNode.light = SCNLight()
    ambientNode.light?.type = .ambient
    ambientNode.light?.color = UIColor(white: ambientLevel, alpha: 1)
    scene.rootNode.addChildNode(ambientNode)

    return scene
}

/// Title + artist texture for the thin -Y bottom edge face.
private func labeledEdgeImage(backgroundColor: UIColor, title: String, artist: String) -> UIImage {
    let width: CGFloat = 1600
    let height: CGFloat = 110
    let textColor = contrastingTextColor(for: backgroundColor)
    let fontSize: CGFloat = 40

    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byTruncatingTail
    paragraph.alignment = .center

    let attributed = NSMutableAttributedString(
        string: title,
        attributes: [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
    )
    attributed.append(NSAttributedString(
        string: " \(artist)",
        attributes: [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
    ))

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        return format
    }())
    return renderer.image { context in
        backgroundColor.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let inset: CGFloat = 20
        let maxWidth = width - inset * 2
        let boundingRect = attributed.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let textRect = CGRect(
            x: inset,
            y: (height - boundingRect.height) / 2,
            width: maxWidth,
            height: boundingRect.height
        )
        attributed.draw(in: textRect)
    }
}

/// White text on dark backgrounds, black text on light backgrounds.
private func contrastingTextColor(for background: UIColor) -> UIColor {
    guard let components = background.cgColor.components, !components.isEmpty else { return .white }
    let r = components[0]
    let g = components.count > 1 ? components[1] : r
    let b = components.count > 2 ? components[2] : r
    let luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return luminance > 0.55 ? .black : .white
}

/// Returns the most prominent color in the image, weighted by saturation and brightness.
private func dominantColor(in image: UIImage?) -> UIColor? {
    guard let image, let cgImage = image.cgImage else { return nil }

    let sampleSize = 40
    var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
    guard let context = CGContext(
        data: &pixels,
        width: sampleSize,
        height: sampleSize,
        bitsPerComponent: 8,
        bytesPerRow: sampleSize * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

    var buckets: [UInt32: (weight: Double, r: Double, g: Double, b: Double)] = [:]

    for index in stride(from: 0, to: pixels.count, by: 4) {
        let r = Double(pixels[index]) / 255
        let g = Double(pixels[index + 1]) / 255
        let b = Double(pixels[index + 2]) / 255
        let alpha = Double(pixels[index + 3]) / 255
        guard alpha > 0.5 else { continue }

        let maxChannel = max(r, g, b)
        let minChannel = min(r, g, b)
        let brightness = (r + g + b) / 3
        let saturation = maxChannel == 0 ? 0 : (maxChannel - minChannel) / maxChannel
        guard brightness > 0.08, brightness < 0.95 else { continue }

        let visibility = saturation * 0.7 + brightness * 0.3
        let key = UInt32((Int(r * 15) << 16) | (Int(g * 15) << 8) | Int(b * 15))

        var bucket = buckets[key] ?? (0, 0, 0, 0)
        bucket.weight += visibility
        bucket.r += r * visibility
        bucket.g += g * visibility
        bucket.b += b * visibility
        buckets[key] = bucket
    }

    guard let dominant = buckets.max(by: { $0.value.weight < $1.value.weight }),
          dominant.value.weight > 0 else { return nil }

    let weight = dominant.value.weight
    let color = UIColor(
        red: dominant.value.r / weight,
        green: dominant.value.g / weight,
        blue: dominant.value.b / weight,
        alpha: 1
    )

    // Avoid near-white edge fills that read as blank white panels.
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    let luminance = 0.299 * r + 0.587 * g + 0.114 * b
    if luminance > 0.85 {
        return UIColor(
            red: r * 0.75,
            green: g * 0.75,
            blue: b * 0.75,
            alpha: 1
        )
    }
    return color
}

#Preview {
    Album3DView()
}
