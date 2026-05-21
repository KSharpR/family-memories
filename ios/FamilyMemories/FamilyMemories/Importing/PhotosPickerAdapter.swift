import Foundation
import PhotosUI
import SwiftUI

enum PhotosPickerAdapter {
    static func loadPickedPhotoData(from items: [PhotosPickerItem]) async -> [PickedPhotoData] {
        var loaded: [PickedPhotoData] = []

        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                continue
            }

            loaded.append(
                PickedPhotoData(
                    filename: item.itemIdentifier.map { "\($0).jpg" } ?? "\(UUID().uuidString).jpg",
                    imageData: data,
                    sourceCreatedAt: nil,
                    sourceAssetIdentifier: item.itemIdentifier
                )
            )
        }

        return loaded
    }
}
