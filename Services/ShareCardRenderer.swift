import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class ShareCardRenderer {
    private var cachedFileURLs: [String: URL] = [:]

    func shareURL(
        for variant: ShareCardVariant,
        viewModel: ExpenseViewModel,
        strings: AppStrings
    ) -> URL? {
        guard let model = viewModel.shareCardModel(for: variant, strings: strings) else {
            return nil
        }

        let cacheKey = cacheKey(for: variant, model: model)
        if let cachedURL = cachedFileURLs[cacheKey], FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        let renderer = ImageRenderer(content: ShareCardView(model: model))
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: 1080, height: 1350)

        guard let image = renderer.uiImage,
              let data = image.pngData() else {
            return nil
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: variant))
        do {
            try data.write(to: fileURL, options: [.atomic])
            cachedFileURLs[cacheKey] = fileURL
            return fileURL
        } catch {
            return nil
        }
    }

    private func cacheKey(for variant: ShareCardVariant, model: ShareCardModel) -> String {
        var components: [String] = [
            variant.rawValue,
            model.badgeLabel,
            model.title,
            model.periodLabel,
            model.bigValueLabel,
            model.symbolName,
            model.message
        ]

        components.append(contentsOf: model.chips.map { "\($0.title)" })
        return components.joined(separator: "|")
    }

    private func fileName(for variant: ShareCardVariant) -> String {
        return "Pocket-Leak-\(variant.rawValue)-\(PocketLeakFormatters.shareCardFileDateFormatter.string(from: .now)).png"
    }
}
