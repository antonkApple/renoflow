import SwiftUI

struct KFImage<Placeholder: View>: View {
    private let url: URL?
    private var placeholderView: Placeholder
    private var fadeDuration: Double = 0

    init(_ url: URL?) where Placeholder == Color {
        self.url = url
        self.placeholderView = Color(.tertiarySystemFill)
    }

    private init(url: URL?, placeholderView: Placeholder, fadeDuration: Double) {
        self.url = url
        self.placeholderView = placeholderView
        self.fadeDuration = fadeDuration
    }

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: fadeDuration))) { phase in
            switch phase {
            case .empty:
                placeholderView
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholderView
            @unknown default:
                placeholderView
            }
        }
        .clipped()
    }

    func placeholder<Content: View>(@ViewBuilder _ content: () -> Content) -> KFImage<Content> {
        KFImage<Content>(url: url, placeholderView: content(), fadeDuration: fadeDuration)
    }

    func fade(duration: Double) -> KFImage<Placeholder> {
        KFImage(url: url, placeholderView: placeholderView, fadeDuration: duration)
    }
}
