import SwiftUI

struct LaunchSplashView: View {
    let phrase: String

    private static let phrases = [
        "Small leaks become big patterns.",
        "Catch the leak before it disappears.",
        "Track the little things.",
        "Spend with intention.",
        "Your money deserves attention."
    ]

    static func randomPhrase() -> String {
        phrases.randomElement() ?? phrases.first ?? "Pocket Leak"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                Text(phrase)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: 280)
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)

                Text("Pocket Leak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
    }
}
