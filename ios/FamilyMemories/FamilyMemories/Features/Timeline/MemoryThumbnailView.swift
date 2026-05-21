import SwiftUI
import UIKit

struct MemoryThumbnailView: View {
    let imageURL: URL?
    var size: CGSize? = CGSize(width: 88, height: 88)
    var cornerRadius: CGFloat = 8

    var body: some View {
        content
            .frame(width: size?.width, height: size?.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if let imageURL, let uiImage = UIImage(contentsOfFile: imageURL.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(.secondary.opacity(0.12))
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
