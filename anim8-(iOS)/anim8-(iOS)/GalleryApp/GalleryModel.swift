import Foundation

struct GalleryItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let dateAdded: String
    let imageName: String
}

extension GalleryItem {
    static let sampleItems: [GalleryItem] = [
        GalleryItem(id: 0, title: "Emerald Portal", dateAdded: "September 17, 2026", imageName: "GalleryPortal"),
        GalleryItem(id: 1, title: "Neon Glow", dateAdded: "September 17, 2026", imageName: "GalleryNeonGlow"),
        GalleryItem(id: 2, title: "Gilded Bust", dateAdded: "September 17, 2026", imageName: "GalleryGildedBust"),
        GalleryItem(id: 3, title: "Neon Tides in Motion", dateAdded: "September 17, 2026", imageName: "GalleryNeonTides"),
        GalleryItem(id: 4, title: "Prism Knight", dateAdded: "September 17, 2026", imageName: "GalleryPrismKnight"),
        GalleryItem(id: 5, title: "Afterimage", dateAdded: "September 17, 2026", imageName: "GalleryAfterimage"),
        GalleryItem(id: 6, title: "Dream and Create", dateAdded: "September 17, 2026", imageName: "GalleryDreamWorlds"),
        GalleryItem(id: 7, title: "All-Seeing Eye", dateAdded: "September 17, 2026", imageName: "GalleryAllSeeingEye"),
        GalleryItem(id: 8, title: "Smudge Effect", dateAdded: "September 17, 2026", imageName: "GallerySmudge"),
        GalleryItem(id: 9, title: "Colour Me Happy", dateAdded: "September 17, 2026", imageName: "GalleryColourMeHappy"),
        GalleryItem(id: 10, title: "Double Exposure", dateAdded: "September 17, 2026", imageName: "GalleryDoubleExposure"),
        GalleryItem(id: 11, title: "Growth", dateAdded: "September 17, 2026", imageName: "GalleryGrowth"),
    ]
}
