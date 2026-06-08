import SwiftUI

struct GlassCardView<Content: View>: View {
    let content: Content
    @Environment(\.appTextSize) private var appTextSize: AppTextSize

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let scale = appTextSize.scale
        content
            .padding(20 * scale)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}
